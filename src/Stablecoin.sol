//SPDX-License-Identifier: MIT

pragma solidity 0.8.27  ;

import {ERC20Burnable, ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Stablecoin is ERC20Burnable, Ownable{
    error Stablecoin__MustBeMoreThanZero();
    error Stablecoin__BurnMoreThanBalance();
    error Stablecoin__NoMintingtoZeroAddress();
    error Stablecoin__AmountMustBeMoreThanZero();


    constructor() ERC20("Stablecoin", "SBT") Ownable(msg.sender) {}

function burn (uint256 _amount) public override onlyOwner{
    uint256 balance = balanceOf(msg.sender);
    if(_amount <= 0){
        revert Stablecoin__MustBeMoreThanZero();
    }
    if (balance < _amount) {
        revert Stablecoin__BurnMoreThanBalance();
    }
    super.burn(_amount);
}

function mint(address _to, uint256 _amount) external onlyOwner returns(bool){
    if(_to == address(0)){
        revert Stablecoin__NoMintingtoZeroAddress();
    }
    if(_amount <= 0){
        revert Stablecoin__AmountMustBeMoreThanZero();
    }
    _mint(_to, _amount);
    return true;

}


} 
