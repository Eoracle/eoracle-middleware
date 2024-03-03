// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// OpenZeppelin
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {DeployEOMiddlewareContracts} from "../../../script/DeployEOMiddlewareContracts.s.sol";

// Middleware contracts
import {EORegistryCoordinator, IEORegistryCoordinator, IBLSApkRegistry, IIndexRegistry, IStakeRegistry, IServiceManager} from "../../../src/EORegistryCoordinator.sol";
import {BLSApkRegistry} from "../../../src/BLSApkRegistry.sol";
import {IndexRegistry} from "../../../src/IndexRegistry.sol";
import {StakeRegistry} from "../../../src/StakeRegistry.sol";
//import {EOServiceManager} from "../src/EOServiceManager.sol";
// Remove mock when EOServiceManager is implemented
import {ServiceManagerMock} from "../../mocks/ServiceManagerMock.sol";
import {OperatorStateRetriever} from "../../../src/OperatorStateRetriever.sol";

contract DeployEOMiddlewareContractsTest is Test, Script {
    DeployEOMiddlewareContracts public deployEOMiddlewareContracts;

    EORegistryCoordinator public registryCoordinator;
    ServiceManagerMock public serviceManager;
    StakeRegistry public stakeRegistry;
    BLSApkRegistry public blsApkRegistry;
    IndexRegistry public indexRegistry;
    OperatorStateRetriever public operatorStateRetriever;
    ProxyAdmin public proxyAdmin;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('goerli'), 10619764);
        deployEOMiddlewareContracts = new DeployEOMiddlewareContracts();
    }

    function testDeployEOMiddlewareContracts() public {
        (registryCoordinator, serviceManager, stakeRegistry, blsApkRegistry, indexRegistry, operatorStateRetriever, proxyAdmin) = deployEOMiddlewareContracts.run();

        address admin = proxyAdmin.getProxyAdmin(TransparentUpgradeableProxy(payable(address(registryCoordinator))));
        assertEq(admin, address(proxyAdmin));

        assertEq(proxyAdmin.owner(), msg.sender);

        assertEq(registryCoordinator.registries(0), address(stakeRegistry));
        assertEq(registryCoordinator.registries(1), address(blsApkRegistry));
        assertEq(registryCoordinator.registries(2), address(indexRegistry));

    }
}