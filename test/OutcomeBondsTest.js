
var OutcomeBondToken = artifacts.require('OutcomeBondToken.sol');
var Voting = artifacts.require('AnybodyDecidesNoCap.sol');

contract('OutcomeBondToken', function(accounts) {
    it('should create an Outcome Bond.', async function() {
        let votingInstance = await Voting.new();
        let tokenInstance = await OutcomeBondToken.new('test', votingInstance.address);
        var tokenName = await tokenInstance.name.call();
        var votingAddress = await tokenInstance.voting.call();
        assert.equal(tokenName, 'test');
        assert.equal(votingAddress, votingInstance.address);
    });
});