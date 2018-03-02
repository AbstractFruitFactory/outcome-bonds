contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) internal balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract IERC20IssuableRedeemable is ERC20
{
    function issue(address target, uint value);
    function redeem(address target, uint value);
}

contract ERC20_IssuableRedeemable is StandardToken, IERC20IssuableRedeemable
{
  address private issuer;
  
  function ERC20_IssuableRedeemable(address _issuer)
  {
    issuer = _issuer;
  }

  function issue(address target, uint value)
  {
    if (msg.sender == issuer)
    {
      balances[target] = balances[target].add(value);
      Transfer(this, target, value);
    }
  }
  function redeem(address target, uint value)
  {
    if (msg.sender == issuer)
    {
      balances[target] = balances[target].sub(value);
      Transfer(target, this, value);
    }
  }
}


contract IVotingMechanism
{
    enum Vote { UNKNOWN, MET, NOT_MET }
    
    function checkVote(address _subject, address _topic) constant returns (Vote result) { return Vote.UNKNOWN; }
    function checkCap(ERC20 _payoutToken, address _subject, address _topic, uint _value) constant returns (bool allowed);

    event Voted(address indexed _subject, address indexed _topic, Vote _vote);
}

contract AnybodyDecidesNoCap is IVotingMechanism
{
    address private creator;
    mapping (address => mapping (address => Vote)) voteStatus;

    
    function checkVote(address _subject, address _topic) constant returns (Vote result) 
    {
        return voteStatus[_subject][_topic];
    }
    
    function checkCap(ERC20 _payoutToken, address _subject, address _topic, uint _value) constant returns (bool allowed)
    {
        return true;
    }
    
    function vote(address _subject, address _topic, Vote _vote)
    {
        if (voteStatus[_subject][_topic] == Vote.UNKNOWN)
        {
            voteStatus[_subject][_topic] = _vote;
            Voted(_subject, _topic, _vote);
           
        }
    }
    
}

contract ERC20_IssuableRedeemable_Factory
{
    function create(address _issuer) returns (IERC20IssuableRedeemable addy)
    {
        return IERC20IssuableRedeemable(new ERC20_IssuableRedeemable(_issuer));
    }
}

library LibSmartMilestonev0
{
    event DeployedToken(address _payoutToken, address _backerToken, address _rewardToken);

    struct Data
    {
        mapping (address => IERC20IssuableRedeemable) backerTokens;
        mapping (address => IERC20IssuableRedeemable) rewardTokens;
        IVotingMechanism voteMechanism;
        ERC20_IssuableRedeemable_Factory erc20factory;
        address subject;
    }
    
    function deployTokens(Data storage self, ERC20 _payoutToken)
    {
        if (self.backerTokens[_payoutToken] == IERC20IssuableRedeemable(0x0))
        {
            // deploy backer and reward token for this payout
            self.backerTokens[_payoutToken] = self.erc20factory.create(this);
            self.rewardTokens[_payoutToken] = self.erc20factory.create(this);
            DeployedToken(_payoutToken, self.backerTokens[_payoutToken], self.rewardTokens[_payoutToken]);
        }
    }
    
    function back(Data storage self, ERC20 _payoutToken, uint _amount)
    {
        // don't allow to back with ether through this
        if (_payoutToken == ERC20(0x0))
            throw;
        
        // 
        if (self.backerTokens[_payoutToken] == ERC20_IssuableRedeemable(0x0))
            return;

        if (!self.voteMechanism.checkCap(_payoutToken, self.subject, this, _amount))
            return;
            
        if (_payoutToken.allowance(msg.sender, this) >= _amount)
        {
            _payoutToken.transferFrom(msg.sender, this, _amount);
            self.backerTokens[_payoutToken].issue(msg.sender, _amount);
            self.rewardTokens[_payoutToken].issue(msg.sender, _amount);
        }
    }

    function backWithEther(Data storage self)
    {
        if (self.backerTokens[address(0x0)] == ERC20_IssuableRedeemable(0x0))
            throw;

        if (!self.voteMechanism.checkCap(ERC20(0x0), self.subject, address(this), msg.value))
            throw;
            
        self.backerTokens[address(0x0)].issue(msg.sender, msg.value);
        self.rewardTokens[address(0x0)].issue(msg.sender, msg.value);
    }

    function redeemBackerToken(Data storage self, ERC20 _payoutToken, uint _amount)
    {
        if (checkVote(self) != IVotingMechanism.Vote.NOT_MET)
            return;
        
        if (self.backerTokens[_payoutToken].balanceOf(msg.sender) >= _amount)
        {
            self.backerTokens[_payoutToken].redeem(msg.sender, _amount);
            if (_payoutToken != ERC20(0x0))
            {
                _payoutToken.transfer(msg.sender, _amount);
            }
            else
            {
                msg.sender.transfer(_amount);
            }
        }
    }

    function checkVote(Data storage self) constant returns (IVotingMechanism.Vote success) 
    {
        return self.voteMechanism.checkVote(self.subject, this);
    }
    
    function redeemRewardToken(Data storage self, ERC20 _payoutToken, uint _amount)
    {
        if (checkVote(self) != IVotingMechanism.Vote.MET)
            return;
        
        
        if (self.rewardTokens[_payoutToken].balanceOf(msg.sender) >= _amount)
        {
            self.rewardTokens[_payoutToken].redeem(msg.sender, _amount);
            if (_payoutToken == ERC20(0x0))
                msg.sender.transfer(_amount);
            else
                _payoutToken.transfer(msg.sender, _amount);
        }
    }

    function redeemBoth(Data storage self, ERC20 _payoutToken, uint _amount)
    {
        if (self.rewardTokens[_payoutToken].balanceOf(msg.sender) >= _amount
                && self.backerTokens[_payoutToken].balanceOf(msg.sender) >= _amount)
        {
            self.rewardTokens[_payoutToken].redeem(msg.sender, _amount);
            self.backerTokens[_payoutToken].redeem(msg.sender, _amount);

            if (_payoutToken != ERC20(0x0))
            {
                _payoutToken.transfer(msg.sender, _amount);
            }
            else
            {
                msg.sender.transfer(_amount);
            }
        }
    }
}


contract ISmartMilestone
{
    // deploy reward and backer tokens for this payout token
    function deployTokens(ERC20 _payoutToken);

    // give msg.sender _amount of reward and backer coins for this ERC20 payout token
    function back(ERC20 _payoutToken, uint _amount);
    
    // get msg.value of reward and backer coins for submitted ether
    function backWithEther() payable;
    
    // if milestone is not met, get _amount of _payoutToken back, if you hold _amount of 
    // backer coins 
    function redeemBackerToken(ERC20 _payoutToken, uint _amount);
    
    // if milestone is met, get _amount of _payoutToken back, if you hold _amount of 
    // reward coins 
    
    function redeemRewardToken(ERC20 _payoutToken, uint _amount);

    // no matter if milestone is met or not, get _amount of _payoutToken back if you hold _amount of
    // both reward and backer coins
    function redeemBoth(ERC20 _payoutToken, uint _amount);

    // check status of milestone
    function checkVote() constant returns (IVotingMechanism.Vote success);
    
    // get the ERC20 backer token matching the payout token
    function getBackerToken(ERC20 _payoutToken) constant returns (ERC20 addy);
    
    // get the ERC20 reward token matching the payout token
    function getRewardToken(ERC20 _payoutToken) constant returns (ERC20 addy);

    // get the subject / "parent" of the smart milestone for better lookup
    function getSubject() constant returns (address addy);

    // get voting mechanism
    function getVotingMechanism() constant returns (IVotingMechanism addy);

    event DeployedToken(address _payoutToken, address _backerToken, address _rewardToken);

}

contract SmartMilestone_v0 is ISmartMilestone
{
    // mapping of payoutToken to it's issueable
    LibSmartMilestonev0.Data private data;
    
    function SmartMilestone_v0(address _subject, IVotingMechanism _voteMechanism, ERC20_IssuableRedeemable_Factory _erc20factory)
    {  
        data.voteMechanism = _voteMechanism;
        data.erc20factory = _erc20factory;
        data.subject = _subject;
    }
    
    // deploy reward and backer tokens for this payout token
    function deployTokens(ERC20 _payoutToken)
    {
        LibSmartMilestonev0.deployTokens(data, _payoutToken);
    }
    

    // give msg.sender _amount of reward and backer coins for this ERC20 payout token
    function back(ERC20 _payoutToken, uint _amount)
    {
        LibSmartMilestonev0.back(data, _payoutToken, _amount);
    }
    
    // get msg.value of reward and backer coins for submitted ether
    function backWithEther() payable
    {
        LibSmartMilestonev0.backWithEther(data);
    }
        
    // if milestone is not met, get _amount of _payoutToken back, if you hold _amount of 
    // backer coins 
    function redeemBackerToken(ERC20 _payoutToken, uint _amount)
    {
        LibSmartMilestonev0.redeemBackerToken(data, _payoutToken, _amount);
    }

    // if milestone is met, get _amount of _payoutToken back, if you hold _amount of 
    // reward coins 
    
    function redeemRewardToken(ERC20 _payoutToken, uint _amount)
    {
        LibSmartMilestonev0.redeemRewardToken(data, _payoutToken, _amount);
    }
    
    // no matter if milestone is met or not, get _amount of _payoutToken back if you hold _amount of
    // both reward and backer coins
    
    function redeemBoth(ERC20 _payoutToken, uint _amount)
    {
        LibSmartMilestonev0.redeemBoth(data, _payoutToken, _amount);
    }
    
    // check status of milestone
    function checkVote() constant returns (IVotingMechanism.Vote success) 
    {
        return LibSmartMilestonev0.checkVote(data);
    }
    
    // get the ERC20 backer token matching the payout token
    function getBackerToken(ERC20 _payoutToken) constant returns (ERC20 addy)
    {
        return data.backerTokens[_payoutToken];
    }
    
    // get the ERC20 reward token matching the payout token
    function getRewardToken(ERC20 _payoutToken) constant returns (ERC20 addy)
    {
        return data.rewardTokens[_payoutToken];
    }
    
    function getSubject() constant returns (address addy)
    {
        return data.subject;
    }

    function getVotingMechanism() constant returns (IVotingMechanism addy)
    {
        return data.voteMechanism;
    }
}

contract SmartMilestone_v0_factory
{
    ERC20_IssuableRedeemable_Factory private erc20factory;
    function SmartMilestone_v0_factory()
    {
        erc20factory = new ERC20_IssuableRedeemable_Factory();
    }
    
    function create(address _subject, IVotingMechanism _voteMechanism) returns (ISmartMilestone addy)
    {
        return ISmartMilestone(new SmartMilestone_v0(_subject, _voteMechanism, erc20factory));
    }
}

contract ISmartMilestoneFactory
{
    function create(address _subject, IVotingMechanism _voteMechanism) returns (ISmartMilestone addy);
}

contract SmartMilestoneCreator
{
    function create(ISmartMilestoneFactory _factory, address _subject, IVotingMechanism _voteMechanism) returns (ISmartMilestone milestone)
    {
        ISmartMilestone ret = _factory.create(_subject, _voteMechanism);
        Created(_factory, _subject, _voteMechanism, ret);
        return ret;
    }
    
    event Created(ISmartMilestoneFactory _factory, address indexed _subject, IVotingMechanism _voteMechanism, ISmartMilestone _milestone);
}