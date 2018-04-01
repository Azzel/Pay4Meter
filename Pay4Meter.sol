pragma solidity ^0.4.0;
contract Pay4meter {
    
    address customer;
    address sensor;
    address owner;
    
    bool lease_status; //true - now leasing; false - now not leasing
    uint256 price; //price for 1 measurement
    uint256 measurement; // measurement of sensor
    uint256 begin_measurement;
    uint256 balance; //now available
    
    uint256 amountForOwner;
    
    struct Leaser {
        uint256 depositToReturn;
        //address leaser;
    }

    mapping(address => Leaser) leasers;

    function Pay4meter(address sensor_init, uint256 price_init) public {
        measurement=0;
        balance=0;
        amountForOwner=0;
        lease_status=false;
        owner = msg.sender;
        sensor = sensor_init;
        price = price_init;
    }
    
    function createLease () public payable {
        require(msg.value > price);
        require(!lease_status);
        
        customer = msg.sender;
        begin_measurement = measurement;
        lease_status = true;
        balance = msg.value;
        
        //add deposit to return of current leaser to balance
        balance += releasDeposit(customer);
    }
    
    function stopLease() public {
        require(msg.sender==customer);
        require(lease_status);
        
        //increase deposit to return of leaser on unused balance
        if (balance > 0) {
            Leaser storage _l = leasers[customer];
            _l.depositToReturn += balance;
        }
        
        lease_status = false;
        balance = 0;
    }

    function stopLeaseEnforce() private {
        require(lease_status);
        lease_status = false;
        balance = 0;
    }
    
    function update_mesurement (uint256 _mesurement) public {
        if (_mesurement > measurement) {
            uint256 amount = price*(_mesurement-measurement);
            if (amount > balance) amount = balance;
            amountForOwner = amountForOwner+amount;
            balance = balance-amount;
            measurement=_mesurement;
            if (balance==0 && lease_status==true) {
            
                stopLeaseEnforce();
            }
        }
    }
        
    function take_amount () public    {
        require(msg.sender==owner);
        require(amountForOwner>0);
        owner.transfer(amountForOwner);
        amountForOwner=0;
    }
    
    function releasDeposit(address _leaser) private returns (uint256 _deposit) {
        Leaser storage _l = leasers[_leaser];
        _deposit = 0;
        if (_l.depositToReturn > 0) {
           _deposit = _l.depositToReturn;
           _l.depositToReturn = 0;
        }
    }
    
    function take_deposit() public {
        uint256 _d = releasDeposit(msg.sender);
        if (_d > 0) {
            msg.sender.transfer(_d);
            balance=0;
        }
    }
    
    function status_lease() public view returns (bool) {
        return lease_status;
    }
    
    function current_balance() public view returns (uint256) {
        return balance;
    }

    function current_measurement() public view returns (uint256) {
        return measurement;
    }
}
