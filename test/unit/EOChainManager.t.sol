// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test, console2} from "forge-std/Test.sol";
import {EOChainManager} from "../../src/EOChainManager.sol";
import {IEOChainManager} from "../../src/interfaces/IEOChainManager.sol";

contract EOChainManagerTest is Test {
    ProxyAdmin private proxyAdmin;
    EOChainManager public chainManager;
    TransparentUpgradeableProxy private transparentProxy;
    address private owner = makeAddr("owner");
    address private registryCoordinator = makeAddr("registryCoordinator");
    address private operator = makeAddr("operator");

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        EOChainManager impl = new EOChainManager();
        proxyAdmin = new ProxyAdmin();
        bytes memory data = abi.encodeWithSelector(EOChainManager.initialize.selector);
        transparentProxy = new TransparentUpgradeableProxy(address(impl), address(proxyAdmin), data);
        vm.stopPrank();
        chainManager = EOChainManager(address(transparentProxy));
    }

    function test_SetRegistryCoordinatorRevertIfNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        chainManager.setRegistryCoordinator(registryCoordinator);
    }

    function test_SetRegistryCoordinator() public {
        assertEq(chainManager.registryCoordinator(), address(0));
        vm.prank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        assertEq(chainManager.registryCoordinator(), registryCoordinator);
    }

    function test_RegisterDataValidatorRevertIfNotRegistryCoordinator() public {
        vm.expectRevert("NotRegistryCoordinator");
        _registerDataValidator(operator, 1000);
    }

    function test_RegisterDataValidatorRevertIfNotWhitelisted() public {
        vm.prank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        vm.startPrank(registryCoordinator);
        vm.expectRevert("NotWhitelisted");
        _registerDataValidator(operator, 1000);
        vm.stopPrank();
    }

    function test_RegisterDataValidator() public {
        vm.startPrank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        vm.stopPrank();
        vm.prank(registryCoordinator);
        _registerDataValidator(operator, 1000);
    }

    function test_RegisterChainValidatorRevertIfNotRegistryCoordinator() public {
        vm.expectRevert("NotRegistryCoordinator");
        _registerChainValidator(operator, 999);
    }

    function test_RegisterChainValidatorRevertIfNotWhitelisted() public {
        vm.prank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        vm.startPrank(registryCoordinator);
        vm.expectRevert("NotWhitelisted");
        _registerChainValidator(operator, 999);
        vm.stopPrank();
    }

    function test_RegisterChainValidator() public {
        vm.startPrank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        chainManager.grantRole(chainManager.CHAIN_VALIDATOR_ROLE(), operator);
        vm.stopPrank();
        vm.prank(registryCoordinator);
        _registerChainValidator(operator, 999);
    }

    function test_DeregisterValidatorRevertIfNotRegistryCoordinator() public {
        vm.startPrank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        vm.stopPrank();

        vm.expectRevert("NotRegistryCoordinator");
        chainManager.deregisterValidator(operator);
    }

    function test_DeregisterValidator() public {
        vm.startPrank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        vm.stopPrank();

        vm.prank(registryCoordinator);
        chainManager.deregisterValidator(operator);
    }

    function test_UpdateOperatorRevertIfNotRegistryCoordinator() public {
        vm.startPrank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        vm.stopPrank();

        vm.expectRevert("NotRegistryCoordinator");
        chainManager.updateOperator(operator, new uint96[](0));
    }

    function test_UpdateOperator() public {
        vm.startPrank(owner);
        chainManager.setRegistryCoordinator(registryCoordinator);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        vm.stopPrank();

        vm.prank(registryCoordinator);
        chainManager.updateOperator(operator, new uint96[](0));
    }

    function _registerDataValidator(address validator, uint96 stake) internal {
        uint96[] memory stakes = new uint96[](1);
        stakes[0] = stake;
        chainManager.registerDataValidator(validator, stakes);
    }

    function _registerChainValidator(address validator, uint96 stake) internal {
        uint256[2] memory signature = [uint256(1), uint256(2)];
        uint256[4] memory publicKey = [uint256(3), uint256(4), uint256(5), uint256(6)];
        uint96[] memory stakes = new uint96[](1);
        stakes[0] = stake;
        chainManager.registerChainValidator(validator, stakes, signature, publicKey);
    }
}
