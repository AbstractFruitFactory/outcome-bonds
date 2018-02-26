pragma solidity ^0.4.17;

import '../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import './IVotingMechanism.sol';

contract OutcomeBondToken is StandardToken {

    string public name;
    mapping (address => uint) private backerTokens;
    address voting;

    function OutcomeBondToken(string _name, address _votingAddress) public {
        name = _name;
        voting = _votingAddress;
    }

    function back() public payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
        backerTokens[msg.sender] += msg.value;
    }

    function redeemBackerTokens(uint _value) public {
        require(_value > 0);
        require(backerTokens[msg.sender] >= _value);
        IVotingMechanism votingContract = IVotingMechanism(voting);
        require(votingContract.checkVote(this) == IVotingMechanism.Vote.NOT_MET);
        backerTokens[msg.sender] -= _value;
        msg.sender.transfer(_value);
    }

    function redeemRewardTokens(uint _value) public {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        IVotingMechanism votingContract = IVotingMechanism(voting);
        require(votingContract.checkVote(this) == IVotingMechanism.Vote.MET);
        balances[msg.sender] -= _value;
        msg.sender.transfer(_value);
    }


}