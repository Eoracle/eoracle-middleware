// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test, console2} from "forge-std/Test.sol";
import {
    EOChainManagerHarness,
    MockRegistrationData,
    MockUpdateData
} from "../../harnesses/EOChainManagerHarness.sol";
import "../../../src/interfaces/IEOChainManager.sol";
import "../../utils/MockAVSDeployer.sol";

contract RegistrationFlowTest is MockAVSDeployer {
    using BN254 for BN254.G1Point;

    EOChainManagerHarness public chainManager;
    TransparentUpgradeableProxy private transparentProxy;
    address private whitelister = makeAddr("whitelister");
    address private operator = makeAddr("operator");

    constructor() {
        numQuorums = 1;
    }

    function setUp() public {
        _deployMockEigenLayerAndAVS();
        vm.deal(whitelister, 100 ether);
        vm.startPrank(whitelister);
        EOChainManagerHarness impl = new EOChainManagerHarness();
        bytes memory data = abi.encodeWithSelector(EOChainManagerHarness.initialize.selector);
        transparentProxy = new TransparentUpgradeableProxy(address(impl), address(proxyAdmin), data);
        chainManager = EOChainManagerHarness(address(transparentProxy));
        chainManager.setRegistryCoordinator(address(registryCoordinator));
        vm.stopPrank();
        assertEq(chainManager.hasRole(chainManager.DEFAULT_ADMIN_ROLE(), whitelister), true);
        vm.startPrank(registryCoordinatorOwner);
        registryCoordinator.setChainManager(EOChainManagerHarness(address(chainManager)));
        vm.stopPrank();
        vm.deal(operator, 100 ether);
    }

    function test_RegisterDataValidatorRevertIfNotWhitelisted() public {
        BN254.G1Point memory pubKey = BN254.hashToG1(keccak256("seed_for_hash"));
        bytes memory quorumNumbers = BitmapUtils.bitmapToBytesArray(1);

        blsApkRegistry.setBLSPublicKey(operator, pubKey);
        _setOperatorWeight(operator, 0, 1000);

        ISignatureUtils.SignatureWithSaltAndExpiry memory signature;
        IEOBLSApkRegistry.PubkeyRegistrationParams memory params;

        cheats.prank(operator);
        vm.expectRevert("NotWhitelisted");
        registryCoordinator.registerOperator(quorumNumbers, params, signature);
    }

    function test_RegisterDataValidator() public {
        vm.startPrank(whitelister);
        assertEq(chainManager.hasRole(chainManager.DATA_VALIDATOR_ROLE(), operator), false);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        assertEq(chainManager.hasRole(chainManager.DATA_VALIDATOR_ROLE(), operator), true);
        vm.stopPrank();

        BN254.G1Point memory pubKey = BN254.hashToG1(keccak256("seed_for_hash"));
        bytes memory quorumNumbers = BitmapUtils.bitmapToBytesArray(1);

        blsApkRegistry.setBLSPublicKey(operator, pubKey);
        _setOperatorWeight(operator, 0, 1000);

        ISignatureUtils.SignatureWithSaltAndExpiry memory signature;
        IEOBLSApkRegistry.PubkeyRegistrationParams memory params;
        uint96[] memory stakes = new uint96[](1);
        stakes[0] = 1000;
        cheats.prank(operator);
        registryCoordinator.registerOperator(quorumNumbers, params, signature);
        MockRegistrationData memory data = chainManager.lastRegistration();
        assertEq(data.operator, operator);
        assertEq(data.stakes[0], stakes[0]);
        assertEq(data.signature[0], 0);
        assertEq(data.signature[1], 0);
    }

    function test_UpdateDataValidator() public {
        vm.startPrank(whitelister);
        assertEq(chainManager.hasRole(chainManager.DATA_VALIDATOR_ROLE(), operator), false);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        assertEq(chainManager.hasRole(chainManager.DATA_VALIDATOR_ROLE(), operator), true);
        vm.stopPrank();

        BN254.G1Point memory pubKey = BN254.hashToG1(keccak256("seed_for_hash"));
        bytes memory quorumNumbers = BitmapUtils.bitmapToBytesArray(1);

        blsApkRegistry.setBLSPublicKey(operator, pubKey);
        _setOperatorWeight(operator, 0, 1000);

        ISignatureUtils.SignatureWithSaltAndExpiry memory signature;
        IEOBLSApkRegistry.PubkeyRegistrationParams memory params;
        cheats.prank(operator);
        registryCoordinator.registerOperator(quorumNumbers, params, signature);
        MockRegistrationData memory data = chainManager.lastRegistration();
        assertEq(data.stakes[0], 1000);

        address[] memory operators = new address[](1);
        operators[0] = operator;
        _setOperatorWeight(operator, 0, 2000);
        registryCoordinator.updateOperators(operators);
        MockUpdateData memory updateData = chainManager.lastUpdate();
        assertEq(updateData.operator, operator);
        assertEq(updateData.stakes[0], 2000);
    }

    function test_RegisterChainValidatorRevertIfNotWhitelisted() public {
        vm.startPrank(whitelister);
        assertEq(chainManager.hasRole(chainManager.DATA_VALIDATOR_ROLE(), operator), false);
        chainManager.grantRole(chainManager.DATA_VALIDATOR_ROLE(), operator);
        assertEq(chainManager.hasRole(chainManager.DATA_VALIDATOR_ROLE(), operator), true);
        vm.stopPrank();

        BN254.G1Point memory pubKey = BN254.hashToG1(keccak256("seed_for_hash"));
        bytes memory quorumNumbers = BitmapUtils.bitmapToBytesArray(1);

        blsApkRegistry.setBLSPublicKey(operator, pubKey);
        _setOperatorWeight(operator, 0, 1000);

        ISignatureUtils.SignatureWithSaltAndExpiry memory signature;
        IEOBLSApkRegistry.PubkeyRegistrationParams memory params;
        params.pubkeyRegistrationSignature = BN254.G1Point(uint256(1), uint256(2));
        params.chainValidatorSignature = BN254.G1Point(uint256(3), uint256(4));
        params.pubkeyG2.X = [uint256(5), uint256(6)];
        params.pubkeyG2.Y = [uint256(7), uint256(8)];

        cheats.prank(operator);
        vm.expectRevert("NotWhitelisted");
        registryCoordinator.registerOperator(quorumNumbers, params, signature);
    }

    function test_RegisterChainValidator() public {
        BN254.G1Point memory pubKey = BN254.hashToG1(keccak256("seed_for_hash"));
        vm.startPrank(whitelister);
        assertEq(chainManager.hasRole(chainManager.CHAIN_VALIDATOR_ROLE(), operator), false);
        chainManager.grantRole(chainManager.CHAIN_VALIDATOR_ROLE(), operator);
        assertEq(chainManager.hasRole(chainManager.CHAIN_VALIDATOR_ROLE(), operator), true);
        vm.stopPrank();
        _registerEOOperatorWithCoordinator(operator, uint256(1), pubKey, 1000, true);
    }
}
