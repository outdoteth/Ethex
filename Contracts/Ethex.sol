pragma solidity ^0.4.11;

import "./SafeMath.sol";
import "./ERC20.sol";

contract exchange {
    
    using SafeMath for uint256;
    
    uint fee = 100;
    address admin;
    
    function exchange() {
        admin = msg.sender;
    }
    
    modifier adminOnly () {
        require(msg.sender == admin);
        _;
    }
    
    function setFee(uint _set) adminOnly {
        _set = fee;
    }
    
    // erc20 balances of user addresses
    mapping(address => mapping(address => uint)) balances;
    
    // list of orderbook and assigned addresses to orderbook id
    mapping(address => mapping(address => uint)) commitments;
    
    struct order {
        address owner;
        address sellToken;
        address buyToken;
        uint amount;
        uint price;
    }
    
    mapping(uint => order) public orderBook;
    uint public orderId = 0;
    
    function createOrder(address erc20token, address acceptedToken, uint amount, uint price) {
        require(balances[msg.sender][erc20token] > 0 && balances[msg.sender][erc20token] > amount);
        require(amount > 0 && price > 0);
        
        //adds order to orderbook
        uint id = orderId.add(1);
        order storage newOrder = orderBook[id];
        orderBook[id] = order(msg.sender, erc20token, acceptedToken, amount, price);
        
        //subtracts balance from the msg.sender's account
        balances[msg.sender][erc20token] = balances[msg.sender][erc20token].sub(amount);
        
        //adds the order to the user's orders
        commitments[msg.sender][erc20token] = commitments[msg.sender][erc20token].add(amount);
    
    }
    
    function cancelOrder(uint id) {
        require(orderBook[id].owner == msg.sender && orderBook[id].amount > 0);
        
        order storage targetOrder = orderBook[id];
        
        commitments[msg.sender][targetOrder.sellToken] = commitments[msg.sender][targetOrder.sellToken].sub(targetOrder.amount);
        balances[msg.sender][targetOrder.sellToken] = balances[msg.sender][targetOrder.sellToken].add(targetOrder.amount);
        
    }
    
    function fillOrder(uint id, uint amount) {
        require (orderBook[id].amount <= amount);
        require (orderBook[id].owner != msg.sender);
        require (balances[msg.sender][orderBook[id].buyToken] >= amount);
        require (amount > 0);
        
        order storage fillOrder = orderBook[id];
        
        //subtract the relevent balances from the two parties
        balances[msg.sender][fillOrder.buyToken] = balances[msg.sender][fillOrder.buyToken].sub(amount);
        balances[fillOrder.owner][fillOrder.sellToken] = balances[fillOrder.owner][fillOrder.sellToken].sub(amount*fillOrder.price);
        
        //add the relevent balances to the two parties
        balances[msg.sender][fillOrder.sellToken] = balances[msg.sender][fillOrder.sellToken].add(amount/fillOrder.price);
        balances[fillOrder.owner][fillOrder.buyToken] = balances[fillOrder.owner][fillOrder.buyToken].add(amount).sub(amount/fee);
        
        //pays fee to the admin
        balances[admin][fillOrder.buyToken] = balances[admin][fillOrder.buyToken].add(amount/fee);
        
        //remove amount from the orderbook
        commitments[fillOrder.owner][fillOrder.sellToken] = commitments[fillOrder.owner][fillOrder.sellToken].sub(fillOrder.amount/fillOrder.price);
    }
    
    function redeem(uint amount);
    function x();

}
