// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from
    "@openzeppelin-upgrades/contracts/access/AccessControlUpgradeable.sol";
import {IEOChainManager} from "./interfaces/IEOChainManager.sol";

/// @title EOChainManager
/// @notice Contract for managing the integration with the EOracle chain.
///         This contract is used to de/register validators and update their stake weights.
///         It is called by the registry coordinator contract
/// @dev In this perliminary version, the contract only checks if the operator is whitelisted. The actual integration
///         with the EOracle chain will be implemented in the future.
/// @dev Inherits IEOChainManager, Ownable2StepUpgradeable, and AccessControlUpgradeable for access control functionalities
contract EOChainManager is IEOChainManager, OwnableUpgradeable, AccessControlUpgradeable {
    /*******************************************************************************
                              CONSTANTS AND IMMUTABLES
    *******************************************************************************/

    /// @notice Public constants for the roles
    bytes32 public constant CHAIN_VALIDATOR_ROLE = keccak256("CHAIN_VALIDATOR");
    bytes32 public constant DATA_VALIDATOR_ROLE = keccak256("DATA_VALIDATOR");

    /*******************************************************************************
                                       STATE
    *******************************************************************************/

    // @notice The address of eoracle middleware RegistryCoordinator
    address public registryCoordinator;
    address public stakeRegistry;

    /*******************************************************************************
                                      MODIFIERS
    *******************************************************************************/

    /// @dev Modifier for registry coordinator
    modifier onlyRegistryCoordinator() {
        require(msg.sender == registryCoordinator, "NotRegistryCoordinator");
        _;
    }

    /// @dev Modifier for stake registry
    modifier onlyStakeRegistry() {
        require(msg.sender == stakeRegistry, "NotStakeRegistry");
        _;
    }

    /// @dev Initializes the contract by setting up roles and ownership
    function initialize() public initializer {
        __AccessControl_init();
        __Ownable_init();

        // Grant the owner the default admin role enabling him to grant and revoke roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*******************************************************************************
                                     SETTERS
    *******************************************************************************/

    /// @dev Sets the registry coordinator which will be the only contract allowed to call the register functions
    function setRegistryCoordinator(
        address _registryCoordinator
    ) external onlyOwner {
        registryCoordinator = _registryCoordinator;
    }

    function setStakeRegistry(
        address _stakeRegistry
    ) external onlyOwner {
        stakeRegistry = _stakeRegistry;
    }
    
    /*******************************************************************************
                                 EXTERNAL FUNCTIONS
    *******************************************************************************/

    /// @inheritdoc IEOChainManager
    /// @dev Registers a data validator
    /// @param operator The address of the operator
    /// @param stakes The stakes of the operator in quorums
    function registerDataValidator(
        address operator,
        uint96[] calldata stakes
    ) external onlyRegistryCoordinator {
        require(hasRole(DATA_VALIDATOR_ROLE, operator), "NotWhitelisted");
        // For now just whitelisting. EO chain integration to come.
        emit DataValidatorRegistered(operator, stakes);
    }

    /// @inheritdoc IEOChainManager
    /// @dev Registers a chain validator
    /// @param operator The address of the operator
    /// @param stakes The stakes of the operator in quorums
    /// @param signature The signature of the operator
    /// @param pubkey The BLS public key of the operator
    function registerChainValidator(
        address operator,
        uint96[] calldata stakes,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) external onlyRegistryCoordinator {
        require(hasRole(CHAIN_VALIDATOR_ROLE, operator), "NotWhitelisted");
        // For now just whitelisting. EO chain integration to come.
        emit ChainValidatorRegistered(operator, stakes);
    }

    /// @inheritdoc IEOChainManager
    /// @dev Deregisters a validator
    /// @param operator The address of the operator
    function deregisterValidator(
        address operator
    ) external onlyRegistryCoordinator {
        // For now just whitelisting. EO chain integration to come.
        emit ValidatorDeregistered(operator);
    }

    /// @inheritdoc IEOChainManager
    /// @dev Updates the stake weights of an operator
    /// @param operator The address of the operator
    /// @param newStakeWeights The new stake weights of the operator in quorums
    function updateOperator(
        address operator,
        uint96[] calldata newStakeWeights
    ) external onlyStakeRegistry {
        // For now just whitelisting. EO chain integration to come.
        emit OperatorUpdated(operator, newStakeWeights);
    }

    // Placeholder for upgradeable contracts
    uint256[48] private __gap;
}
