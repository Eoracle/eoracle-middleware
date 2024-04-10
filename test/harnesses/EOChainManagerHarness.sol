pragma solidity ^0.8.12;

import {EOChainManager} from "../../src/EOChainManager.sol";

struct MockRegistrationData {
    address operator;
    uint96[] stakes;
    uint256[2] signature;
    uint256[4] pubkey;
}

struct MockUpdateData {
    address operator;
    uint96[] stakes;
}

contract EOChainManagerHarness is EOChainManager {
    MockRegistrationData private _lastRegistration;
    MockUpdateData private _lastUpdate;
    address private _lastDeregistration;

    function initialize() public override initializer {
        super.initialize();
    }

    function registerDataValidator(
        address operator,
        uint96[] calldata stakes
    ) external override onlyRegistryCoordinator {
        require(hasRole(DATA_VALIDATOR_ROLE, operator), "NotWhitelisted");
        _lastRegistration = MockRegistrationData(
            operator,
            stakes,
            [uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );
    }

    function lastRegistration() external view returns (MockRegistrationData memory) {
        return _lastRegistration;
    }

    function lastUpdate() external view returns (MockUpdateData memory) {
        return _lastUpdate;
    }

    function lastDeregistration() external view returns (address) {
        return _lastDeregistration;
    }

    function registerChainValidator(
        address operator,
        uint96[] calldata stakes,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) external override {
        require(hasRole(CHAIN_VALIDATOR_ROLE, operator), "NotWhitelisted");
        _lastRegistration = MockRegistrationData(operator, stakes, signature, pubkey);
    }

    function deregisterValidator(address operator) external override {
        _lastDeregistration = operator;
    }

    function updateOperator(
        address operator,
        uint96[] calldata newStakeWeights
    ) external override {
        _lastUpdate = MockUpdateData(operator, newStakeWeights);
    }
}
