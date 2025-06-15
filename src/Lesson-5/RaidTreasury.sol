// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RaidTreasury { 

    error CallerIsNotOwner();

    // @audit informational: Getter exist, consider using private visibility
    mapping(address => uint256) public treasury; 
    bool public withdrawn;

    /// @dev Fake GOLD token address
    address immutable goldAddress;
    /// @dev Fake GOLD token interface
    IERC20 public gold;
    address public owner;

    constructor(address _goldAddress) {
        owner = msg.sender;
        treasury[msg.sender] = 10000 * (1 ether);

        goldAddress = _goldAddress;
        gold = IERC20(_goldAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert CallerIsNotOwner();
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        require(withdrawn == false, "RaidTreasury: Gold Token Withdrawn");
        treasury[msg.sender] += msg.value;

        if (treasury[msg.sender] > treasury[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return treasury[msg.sender];
    }

    function withdraw() public onlyOwner {
        // @audit Low: transfer status is not checked
        // @audit Low: withdrawn set to true in the end indicating withdrawal has made, but not checked at the top
        gold.transfer(msg.sender, gold.balanceOf(address(this)));
        withdrawn = true;
    }

    receive() external payable {
        require(msg.value > 0 && treasury[msg.sender] > 0);
        // @audit high: in `contribute` owner is granted when msg.sender send the most funds, 
        //              but there's no checks here before granding owner to msg.sender, allowing
        //              anyone to become the owner, thereby withdrawing the Gold Token
        owner = msg.sender;
    }
}
