// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IStrategy} from "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";
import {IServiceManager} from "../interfaces/IServiceManager.sol";

import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {CheckpointsUpgradeable} from "@openzeppelin-upgrades/contracts/utils/CheckpointsUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import {SignatureCheckerUpgradeable} from "@openzeppelin-upgrades/contracts/utils/cryptography/SignatureCheckerUpgradeable.sol";
import {IERC1271Upgradeable} from "@openzeppelin-upgrades/contracts/interfaces/IERC1271Upgradeable.sol";

struct StrategyParams {
    IStrategy strategy; // The strategy contract reference
    uint96 multiplier; // The multiplier applied to the strategy
}

struct Quorum {
    StrategyParams[] strategies; // An array of strategy parameters to define the quorum
}

abstract contract ECDSAStakeRegistryEventsAndErrors {
    /// @notice Emitted when the system registers an operator
    /// @param _operator The address of the registered operator
    /// @param _avs The address of the associated AVS
    event OperatorRegistered(address indexed _operator, address indexed _avs);

    /// @notice Emitted when the system deregisters an operator
    /// @param _operator The address of the deregistered operator
    /// @param _avs The address of the associated AVS
    event OperatorDeregistered(address indexed _operator, address indexed _avs);

    /// @notice Emitted when the system updates the quorum
    /// @param _old The previous quorum configuration
    /// @param _new The new quorum configuration
    event QuorumUpdated(Quorum _old, Quorum _new);

    /// @notice Emitted when the weight required to be an operator changes
    /// @param oldMinimumWeight The previous weight
    /// @param newMinimumWeight The updated weight
    event UpdateMinimumWeight(uint256 oldMinimumWeight, uint256 newMinimumWeight);

    /// @notice Emitted when the system updates an operator's weight
    /// @param _operator The address of the operator updated
    /// @param oldWeight The operator's weight before the update
    /// @param newWeight The operator's weight after the update
    event OperatorWeightUpdated(address indexed _operator, uint256 oldWeight, uint256 newWeight);

    /// @notice Emitted when the system updates the total weight
    /// @param oldTotalWeight The total weight before the update
    /// @param newTotalWeight The total weight after the update
    event TotalWeightUpdated(uint256 oldTotalWeight, uint256 newTotalWeight);

    /// @notice Emits when setting a new threshold weight.
    event ThresholdWeightUpdated(uint256 _thresholdWeight);

    /// @notice Indicates when the lengths of the signers array and signatures array do not match.
    error LengthMismatch();

    /// @notice Indicates encountering an invalid length for the signers or signatures array.
    error InvalidLength();

    /// @notice Indicates encountering an invalid signature.
    error InvalidSignature();

    /// @notice Indicates the total signed stake fails to meet the required threshold.
    error InsufficientSignedStake();

    /// @notice Indicates an individual signer's weight fails to meet the required threshold.
    error InsufficientWeight();

    /// @notice Indicates the quorum is invalid
    error InvalidQuorum();

    /// @notice Indicates the system finds a list of items unsorted
    error NotSorted();

    error OperatorAlreadyRegistered();

    error OperatorNotRegistered();
}

abstract contract ECDSAStakeRegistryStorage is ECDSAStakeRegistryEventsAndErrors {
    /// @notice Manages staking delegations through the DelegationManager interface
    IDelegationManager internal immutable DELEGATION_MANAGER;

    /// @dev The total amount of multipliers to weigh stakes
    uint256 internal constant BPS = 10_000;

    /// @notice Stores the current quorum configuration
    Quorum internal quorum;

    /// @notice Specifies the weight required to become an operator
    uint256 public minimumWeight;

    /// @notice Holds the address of the service manager
    address internal serviceManager;

    /// @notice Defines the duration after which the stake's weight expires.
    uint256 internal stakeExpiry;

    /// @notice Sets the threshold weight that signatures must meet to be valid.
    uint256 internal thresholdWeightBps;

    /// @notice Tracks the total stake history over time using checkpoints
    CheckpointsUpgradeable.History internal _totalWeightHistory;

    /// @notice Maps operator addresses to their respective stake histories using checkpoints
    mapping(address => CheckpointsUpgradeable.History) internal _operatorWeightHistory;

    /// @notice Maps an operator to their registration status
    mapping(address => bool) internal _operatorRegistered;

    /// @param _delegationManager Connects this registry with the DelegationManager
    constructor(IDelegationManager _delegationManager) {
        DELEGATION_MANAGER = _delegationManager;
    }

    // slither-disable-next-line shadowing-state
    /// @dev Reserves storage slots for future upgrades
    // solhint-disable-next-line
    uint256[42] private __gap;
}

/// @title ECDSA Stake Registry
/// @notice THIS CONTRACT IS NOT AUDITED
/// @notice Manages operator registration and quorum updates for a staking system using ECDSA signatures.
/// @dev Extends OpenZeppelin's upgradeable Ownable and Pausable patterns to ensure upgradability and pause functionality.
contract ECDSAStakeRegistry is
    IERC1271Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ECDSAStakeRegistryStorage
{
    using SignatureCheckerUpgradeable for address;
    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;

    constructor(
        IDelegationManager _delegationManager
    ) ECDSAStakeRegistryStorage(_delegationManager) {
        // _disableInitializers();
    }

    function initialize(
        address _serviceManager,
        uint256 _thresholdWeightBps,
        Quorum memory _quorum
    ) external initializer {
        __ECDSAStakeRegistry_init(_serviceManager, _thresholdWeightBps, _quorum);
    }

    /// @notice Registers a new operator using a provided signature
    /// @param _operatorSignature Contains the operator's signature, salt, and expiry
    function registerOperatorWithSignature(
        address _operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature
    ) external {
        _registerOperatorWithSig(_operator, _operatorSignature);
    }

    /// @notice Deregisters an existing operator
    function deregisterOperator() external {
        _deregisterOperator(msg.sender);
    }

    /**
     * @notice Updates the StakeRegistry's view of one or more operators' stakes.
     * @dev Queries stakes from the Eigenlayer core DelegationManager contract
     * @param _operators A list of operator addresses to update
     */
    function updateOperators(address[] memory _operators) external {
        for (uint256 i; i < _operators.length; i++) {
            _updateOperatorWeight(_operators[i]);
        }
    }

    /// @notice Updates the strategies and their weights for the quourum
    /// @dev Access controlled to the contract owner
    /// @param _quorum The new quorum configuration
    function updateQuorumConfig(Quorum memory _quorum) external onlyOwner {
        _updateQuorumConfig(_quorum);
    }

    /// @notice Updates the weight an operator must have to join the operator set
    /// @dev Access controlled to the contract owner
    /// @param _newMinimumWeight The new weight an operator must have to join the operator set
    function updateMinimumWeight(uint256 _newMinimumWeight) external onlyOwner {
        minimumWeight = _newMinimumWeight;
    }

    /**
     * @notice Adjusts the threshold weight for valid signatures.
     * @param _thresholdWeightBps The updated threshold weight.
     */
    function updateStakeThreshold(uint256 _thresholdWeightBps) external onlyOwner {
        _updateStakeThreshold(_thresholdWeightBps);
    }

    function isValidSignature(
        bytes32 _dataHash,
        bytes memory _signatureData
    ) external view returns (bytes4) {
        (address[] memory signers, bytes[] memory signatures, uint32 referenceBlock) = abi.decode(
            _signatureData,
            (address[], bytes[], uint32)
        );
        _checkSignatures(_dataHash, signers, signatures, referenceBlock);
        return IERC1271Upgradeable.isValidSignature.selector;
    }

    /// @notice Retrieves the current stake quorum details.
    /// @return Quorum - The current quorum of strategies and weights
    function stakeQuorum() external view returns (Quorum memory) {
        return quorum;
    }

    /// @notice Retrieves the last recorded weight for a given operator.
    /// @param _operator The address of the operator.
    /// @return uint256 - The latest weight of the operator.
    function getLastCheckpointOperatorWeight(address _operator) external view returns (uint256) {
        return _operatorWeightHistory[_operator].latest();
    }

    /// @notice Retrieves the last recorded total weight across all operators.
    /// @return uint256 - The latest total weight.
    function getLastCheckpointTotalWeight() external view returns (uint256) {
        return _totalWeightHistory.latest();
    }

    /// @notice Retrieves the operator's weight at a specific block number.
    /// @param _operator The address of the operator.
    /// @param _blockNumber The block number to get the operator weight for the quorum
    /// @return uint256 - The weight of the operator at the given block.
    function getOperatorWeightAtBlock(
        address _operator,
        uint32 _blockNumber
    ) external view returns (uint256) {
        return _operatorWeightHistory[_operator].getAtBlock(_blockNumber);
    }

    /// @notice Retrieves the total weight at a specific block number.
    /// @param _blockNumber The block number to get the total weight for the quorum
    /// @return uint256 - The total weight at the given block.
    function getLastCheckpointTotalWeightAtBlock(
        uint32 _blockNumber
    ) external view returns (uint256) {
        return _totalWeightHistory.getAtBlock(_blockNumber);
    }

    function operatorRegistered(address _operator) external view returns (bool) {
        return _operatorRegistered[_operator];
    }

    /// @notice Calculates the current weight of an operator based on their delegated stake in the strategies considered in the quourm
    /// @param _operator The address of the operator.
    /// @return uint256 - The current weight of the operator; returns 0 if below the threshold.
    function getOperatorWeight(address _operator) public view returns (uint256) {
        StrategyParams[] memory strategies = quorum.strategies;
        uint256 weight;
        uint256 sharesAmount;
        for (uint256 i; i < strategies.length; i++) {
            sharesAmount = DELEGATION_MANAGER.operatorShares(_operator, strategies[i].strategy);
            weight += sharesAmount * strategies[i].multiplier;
        }
        weight = weight / BPS;
        return weight >= minimumWeight ? weight : 0;
    }

    /// @notice Initializes state for the StakeRegistry
    /// @param _serviceManager The AVS' ServiceManager contract's address
    function __ECDSAStakeRegistry_init(
        address _serviceManager,
        uint256 _thresholdWeightBps,
        Quorum memory _quorum
    ) internal onlyInitializing {
        serviceManager = _serviceManager;
        _updateStakeThreshold(_thresholdWeightBps);
        _updateQuorumConfig(_quorum);
        __Ownable_init();
        __Pausable_init();
    }

    function _updateStakeThreshold(uint256 _thresholdWeightBps) internal {
        thresholdWeightBps = _thresholdWeightBps;
        emit ThresholdWeightUpdated(_thresholdWeightBps);
    }

    /// @dev Internal function to set the quorum configuration
    /// @param _quorum The new quorum configuration to set
    function _updateQuorumConfig(Quorum memory _quorum) internal {
        if (!_isValidQuorum(_quorum)) revert InvalidQuorum();
        Quorum memory oldQuorum = quorum;
        delete quorum;
        for (uint256 i; i < _quorum.strategies.length; i++) {
            quorum.strategies.push(_quorum.strategies[i]);
        }
        emit QuorumUpdated(oldQuorum, _quorum);
    }

    /// @dev Internal function to deregister an operator
    /// @param _operator The operator's address to deregister
    function _deregisterOperator(address _operator) internal {
        if (!_operatorRegistered[_operator]) revert OperatorNotRegistered();
        delete _operatorRegistered[_operator];
        _updateOperatorWeight(_operator);
        IServiceManager(serviceManager).deregisterOperatorFromAVS(_operator);
        emit OperatorDeregistered(_operator, address(serviceManager));
    }

    /// @dev registers an operator through a provided signature
    /// @param _operatorSignature Contains the operator's signature, salt, and expiry
    function _registerOperatorWithSig(
        address _operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature
    ) internal {
        if (_operatorRegistered[_operator]) revert OperatorAlreadyRegistered();
        _operatorRegistered[_operator] = true;
        _updateOperatorWeight(_operator);
        IServiceManager(serviceManager).registerOperatorToAVS(_operator, _operatorSignature);
        emit OperatorRegistered(_operator, serviceManager);
    }

    /// @notice Updates the weight of an operator and returns the previous and current weights.
    /// @param _operator The address of the operator to update the weight of.
    function _updateOperatorWeight(address _operator) internal {
        int256 delta;
        uint256 oldWeight;
        uint256 newWeight;
        if (!_operatorRegistered[_operator]) {
            (oldWeight, ) = _operatorWeightHistory[_operator].push(0);
            delta -= int(oldWeight);
        } else {
            newWeight = getOperatorWeight(_operator);
            (oldWeight, ) = _operatorWeightHistory[_operator].push(newWeight);
            delta = int256(newWeight) - int256(oldWeight);
        }
        _updateTotalWeight(delta);
        emit OperatorWeightUpdated(_operator, oldWeight, newWeight);
    }

    /// @dev Internal function to update the total weight of the stake
    /// @param delta The change in stake applied last total weight
    /// @return oldTotalWeight The weight before the update
    /// @return newTotalWeight The updated weight after applying the delta
    function _updateTotalWeight(
        int256 delta
    ) internal returns (uint256 oldTotalWeight, uint256 newTotalWeight) {
        oldTotalWeight = _totalWeightHistory.latest();
        int256 newWeight = int256(oldTotalWeight) + delta;
        newTotalWeight = uint256(newWeight);
        _totalWeightHistory.push(newTotalWeight);
        emit TotalWeightUpdated(oldTotalWeight, newTotalWeight);
    }

    /// @dev Verifies a quorum has:
    ///     1. Weights that add to 10_000 basis points
    ///     2. There are no duplicate strategies considered in the quorum
    /// @param _quorum The new quorum configuration
    /// @return bool Indicates if the quorum is valid
    function _isValidQuorum(Quorum memory _quorum) internal pure returns (bool) {
        StrategyParams[] memory strategies = _quorum.strategies;
        address lastStrategy;
        address currentStrategy;
        uint256 totalMultiplier;
        for (uint256 i; i < strategies.length; i++) {
            currentStrategy = address(strategies[i].strategy);
            if (lastStrategy >= currentStrategy) revert NotSorted();
            lastStrategy = currentStrategy;
            totalMultiplier += strategies[i].multiplier;
        }
        if (totalMultiplier != BPS) return false;
        return true;
    }

    /**
     * @notice Common logic to verify a batch of ECDSA signatures against a hash, using either last stake weight or at a specific block.
     * @param _dataHash The hash of the data the signers endorsed.
     * @param _signers A collection of addresses that endorsed the data hash.
     * @param _signatures A collection of signatures matching the signers.
     * @param _referenceBlock The block number for evaluating stake weight; use max uint32 for latest weight.
     */
    function _checkSignatures(
        bytes32 _dataHash,
        address[] memory _signers,
        bytes[] memory _signatures,
        uint32 _referenceBlock
    ) internal view {
        uint256 signersLength = _signers.length;
        address lastSigner;
        uint256 signedWeight;

        _validateSignaturesLength(signersLength, _signatures.length);
        for (uint256 i; i < signersLength; i++) {
            address currentSigner = _signers[i];

            _validateSortedSigners(lastSigner, currentSigner);
            _validateSignature(currentSigner, _dataHash, _signatures[i]);

            lastSigner = currentSigner;
            uint256 operatorWeight = _getOperatorWeight(currentSigner, _referenceBlock);
            signedWeight += operatorWeight;
        }

        _validateThresholdStake(signedWeight, _referenceBlock);
    }

    /// @notice Validates that the number of signers equals the number of signatures, and neither is zero.
    /// @param _signersLength The number of signers.
    /// @param _signaturesLength The number of signatures.
    function _validateSignaturesLength(
        uint256 _signersLength,
        uint256 _signaturesLength
    ) internal pure {
        if (_signersLength != _signaturesLength) revert LengthMismatch();
        if (_signersLength == 0) revert InvalidLength();
    }

    /// @notice Ensures that signers are sorted in ascending order by address.
    /// @param _lastSigner The address of the last signer.
    /// @param _currentSigner The address of the current signer.
    function _validateSortedSigners(address _lastSigner, address _currentSigner) internal pure {
        if (_lastSigner >= _currentSigner) revert NotSorted();
    }

    /// @notice Validates a given signature against the signer's address and data hash.
    /// @param _signer The address of the signer to validate.
    /// @param _dataHash The hash of the data that is signed.
    /// @param _signature The signature to validate.
    function _validateSignature(
        address _signer,
        bytes32 _dataHash,
        bytes memory _signature
    ) internal view {
        if (!_signer.isValidSignatureNow(_dataHash, _signature)) revert InvalidSignature();
    }

    /// @notice Retrieves the operator weight for a signer, either at the last checkpoint or a specified block.
    /// @param _signer The address of the signer whose weight is returned.
    /// @param _referenceBlock The block number to query the operator's weight at, or the maximum uint32 value for the last checkpoint.
    /// @return The weight of the operator.
    function _getOperatorWeight(
        address _signer,
        uint32 _referenceBlock
    ) internal view returns (uint256) {
        if (_referenceBlock == type(uint32).max) {
            return _operatorWeightHistory[_signer].latest();
        } else {
            return _operatorWeightHistory[_signer].getAtBlock(_referenceBlock);
        }
    }

    function _getTotalWeight(uint32 _referenceBlock) internal view returns (uint256) {
        if (_referenceBlock == type(uint32).max) {
            return _totalWeightHistory.latest();
        } else {
            return _totalWeightHistory.getAtBlock(_referenceBlock);
        }
    }

    /// @notice Validates that the cumulative stake of signed messages meets or exceeds the required threshold.
    /// @param _signedWeight The cumulative weight of the signers that have signed the message.
    /// @param _referenceBlock The block number to verify the stake threshold for
    function _validateThresholdStake(uint256 _signedWeight, uint32 _referenceBlock) internal view {
        uint256 totalWeight = _getTotalWeight(_referenceBlock);
        if (thresholdWeightBps > (_signedWeight * BPS) / totalWeight)
            revert InsufficientSignedStake();
    }
}