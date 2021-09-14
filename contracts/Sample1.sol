pragma solidity 0.8.6;

import "./lib/BytesLib.sol";

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external;
}

interface IProxy {
    function batchExec(address[] calldata tos, bytes32[] calldata configs, bytes[] memory datas) external payable;
}



/**
 * @title PolygonGrantsHackthon sample 1. 
 * @notice This contract invokes Furucombo proxy to achieve swap and deposit 
 * 
 */
contract Sample1 {
    using BytesLib for bytes;
    
    address public constant HFUNDS = 0x3B3f747aC68750Eb936e9116141b79358579DE84;
    address public constant HQUICKSWAP = 0x6107114BDf5691ADEE675Ea6E9f09d34c6338cc4;
    address public constant HAAVEV2 = 0xD4E8f7FfDF98F7C170A48A31d2f6d358829878Af; 
    address public constant amDAI = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;

    IProxy public furucomboProxy;
    
    
    
    constructor() public {
        /*
        * Furucombo proxy: 0x125d2E4a83bBba4e6f51a244c494f9A1958D20BB
        */
        furucomboProxy = IProxy(0x125d2E4a83bBba4e6f51a244c494f9A1958D20BB);
    }


    function exec() external payable{
        // setup tos
        address[] memory tos = getTos();
        
        // setup configs
        bytes32[] memory configs = getConfigs();

        // setup datas
        bytes[] memory datas = getDatas(msg.value);

        try furucomboProxy.batchExec{value: msg.value}(tos, configs, datas) {

        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("fail...!");
        }
        
        // return amDAI to user
        uint256 amDaiBalance = IERC20(amDAI).balanceOf(address(this));
        IERC20(amDAI).transfer(msg.sender, amDaiBalance);
        
    }

    function getTos() private pure returns (address[] memory){
        address[] memory tos = new address[](2);
        tos[0] = HQUICKSWAP;
        tos[1] = HAAVEV2;
        // tos[2] = HFunds;
        return tos;
    }

    function getConfigs() private pure returns (bytes32[] memory){
        bytes32[] memory r = new bytes32[](2);
        r[0] = bytes32(0x0001000000000000000000000000000000000000000000000000000000000000);
        r[1] = bytes32(0x0100000000000000000200ffffffffffffffffffffffffffffffffffffffffff);
        // r[2] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
        return r;
    }

    function getDatas(uint256 amount2Swap) private pure returns (bytes[] memory){
        bytes[] memory result = new bytes[](2);

        
        bytes memory firstHandlerFuncSelector = abi.encodePacked(bytes4(keccak256("swapExactETHForTokens(uint256,uint256,address[])")));
        bytes memory amount = abi.encode(amount2Swap);
        bytes memory firstHandlerRemainingDatas = hex"0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000d500b1d8e8ef31e21c99d1db9a6444d3adf12700000000000000000000000007ceb23fd6bc0add59e62ac25578270cff1b9f6190000000000000000000000008f3cf7ad23cd3cadbd9735aff958023239c6a063";    
        bytes memory firstHandlerDatas = firstHandlerFuncSelector.concat(amount).concat(firstHandlerRemainingDatas);
        
        bytes memory secondHandlerDatas = hex"47e7ef240000000000000000000000008f3cf7ad23cd3cadbd9735aff958023239c6a0630000000000000000000000000000000000000000000000000de0b6b3a7640000";
        // bytes memory thirdHandlerDatas = hex"db71410e000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000020000000000000000000000008f3cf7ad23cd3cadbd9735aff958023239c6a06300000000000000000000000027f8d03b3a2196956ed754badc28d73be8830a6e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000036e51ce17360297000";
        
        result[0] = firstHandlerDatas;
        result[1] = secondHandlerDatas;
        // result[2] = thirdHandlerDatas;
        return result;
    }
}
