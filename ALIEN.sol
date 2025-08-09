// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ALIEN_V2 is Ownable, Pausable, ReentrancyGuard {
    string public name = "ALIEN Token";
    string public symbol = "ALIEN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10**uint256(decimals);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event AddressBlacklisted(address indexed account, bool status);
    
    constructor(address initialOwner) Ownable(initialOwner) {
        balanceOf[initialOwner] = totalSupply;
        emit Transfer(address(0), initialOwner, totalSupply);
    }
    
    // Основные ERC-20 функции
    function transfer(address _to, uint256 _value) public whenNotPaused nonReentrant returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(!blacklist[msg.sender] && !blacklist[_to], "Address blacklisted");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        require(!blacklist[_from] && !blacklist[_to], "Address blacklisted");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        require(!blacklist[msg.sender] && !blacklist[_spender], "Address blacklisted");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused nonReentrant returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(!blacklist[_from] && !blacklist[_to] && !blacklist[msg.sender], "Address blacklisted");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    // Функции владельца
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid address");
        require(!blacklist[_to], "Address blacklisted");
        
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit TokensMinted(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }
    
    function burn(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        require(!blacklist[msg.sender], "Address blacklisted");
        
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit TokensBurned(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
    
    function burnFrom(address _from, uint256 _amount) public onlyOwner {
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(!blacklist[_from], "Address blacklisted");
        
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
        emit TokensBurned(_from, _amount);
        emit Transfer(_from, address(0), _amount);
    }
    
    // Функции управления
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    function setBlacklist(address _address, bool _status) public onlyOwner {
        blacklist[_address] = _status;
        emit AddressBlacklisted(_address, _status);
    }
    
    function batchSetBlacklist(address[] memory _addresses, bool _status) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = _status;
            emit AddressBlacklisted(_addresses[i], _status);
        }
    }
    
    // Информационные функции
    function getBlacklistStatus(address _address) public view returns (bool) {
        return blacklist[_address];
    }
    
    function getContractInfo() public view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 tokenTotalSupply,
        bool isPaused,
        address contractOwner
    ) {
        return (name, symbol, decimals, totalSupply, paused(), owner());
    }
} 