pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {CowDungerModule} from "../src/CowDungerModule.sol";
import {ISafe} from "../src/interfaces/safe/ISafe.sol";
import {CowDungerResolver} from "../src/CowDungerResolver.sol";

contract ModuleCheckerTest is Test {
    ISafe safe;
    address signer;
    address automator;
    address taskCreator;
    CowDungerModule module;
    CowDungerResolver resolver;

    function setUp() public {
        vm.createSelectFork("testnet");
        safe = ISafe(payable(address(0x206C89813cbDE8E14582Ff94F3F1A1728C39a300)));
        signer = 0xA0c60A3Bf0934869f03955f3431E044059B03E62;
        automator = 0xc1C6805B857Bef1f412519C4A842522431aFed39;
        taskCreator = 0xF381dfd7a139caaB83c26140e5595C0b85DDadCd;

        vm.startPrank(signer);

        module = new CowDungerModule(address(safe), automator, taskCreator);
        resolver = new CowDungerResolver();

        address[] memory tokens = new address[](1);
        tokens[0] = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        module.addTokensWhitelist(tokens);

        vm.stopPrank();
    }

    function test_checker() public {
        resolver.checker(address(module));
    }
}
