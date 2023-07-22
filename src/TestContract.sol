pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TestContract is Ownable {
    uint256 public value1;
    uint256 public value2;
    uint256 public value3;

    function setValue1(uint256 _value) public onlyOwner {
        value1 = _value;
    }

    function setValue2(uint256 _value) public onlyOwner {
        value2 = _value;
    }

    function setValue3(uint256 _value) public onlyOwner {
        value3 = _value;
    }
}
