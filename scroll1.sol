// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ScrolldropToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 22000000000 * 10 ** 18;
    uint256 public constant INITIAL_SUPPLY = TOTAL_SUPPLY * 10 / 100;
    uint256 public constant VESTING_PERIOD = 12 * 30 days; // 12 months in days
    uint256 public constant STAKING_PERIOD = 7 days;

    mapping(address => uint256) public vestingStart;
    mapping(address => uint256) public vested;

    constructor() ERC20("Scrolldrop", "SCRL") {
        _mint(msg.sender, INITIAL_SUPPLY);
        _approve(address(this), owner(), TOTAL_SUPPLY);
    }

    function vest() external {
        require(vested[msg.sender] == 0, "Already vested");
        vestingStart[msg.sender] = block.timestamp;
        vested[msg.sender] = TOTAL_SUPPLY - INITIAL_SUPPLY;
    }

    function claim() external {
        require(vestingStart[msg.sender] != 0, "Not vested");
        require(block.timestamp >= vestingStart[msg.sender] + VESTING_PERIOD, "Vesting period not ended");
        _transfer(address(this), msg.sender, vested[msg.sender]);
        vested[msg.sender] = 0;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        _transfer(msg.sender, address(this), amount);
        StakingContract stakingContract = new StakingContract(msg.sender, amount, block.timestamp);
        emit Staked(address(stakingContract), msg.sender, amount, block.timestamp);
    }

    function unstake(address stakingContractAddress) external {
        StakingContract stakingContract = StakingContract(stakingContractAddress);
        require(stakingContract.staker() == msg.sender, "Not staker");
        require(block.timestamp >= stakingContract.startTime() + STAKING_PERIOD, "Staking period not ended");
        uint256 amount = stakingContract.amount();
        _transfer(address(this), msg.sender, amount);
        stakingContract.close();
        emit Unstaked(stakingContractAddress, msg.sender, amount, block.timestamp);
    }

    event Staked(address indexed stakingContract, address indexed staker, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed stakingContract, address indexed staker, uint256 amount, uint256 timestamp);
}

contract StakingContract is Ownable {
    address public staker;
    uint256 public amount;
    uint256 public startTime;

    constructor(address _staker, uint256 _amount, uint256 _startTime) {
        staker = _staker;
        amount = _amount;
        startTime = _startTime;
    }

    function close() external onlyOwner {
        selfdestruct(payable(owner()));
    }

    function staker() external view returns (address) {
        return staker;
    }

    function amount() external view returns (uint256) {
        return amount;
    }

    function startTime() external view returns (uint256) {
        return startTime;
    }
}