pragma solidity ^0.4.17;

import '../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract IVotingMechanism {
    enum Vote { UNKNOWN, MET, NOT_MET }
    
    function checkVote(address _subject) constant returns (Vote result) { return Vote.UNKNOWN; }
    function checkCap(ERC20 _payoutToken, address _subject, address _topic, uint _value) constant returns (bool allowed);
    function vote(address _subject, address _topic, Vote _vote);

    event Voted(address indexed _subject, address indexed _topic, Vote _vote);
}