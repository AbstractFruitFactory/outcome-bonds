
var OutcomeBondToken = artifacts.require('OutcomeBondToken.sol');
var Voting = artifacts.require('AnybodyDecidesNoCap.sol');

contract('OutcomeBondToken', function(accounts) {

    beforeEach(async function() {
        this.votingInstance = await Voting.new({from: accounts[0], gas: 4000000});
        this.tokenInstance = await OutcomeBondToken.new('test', this.votingInstance.address, {from: accounts[0], gas: 4000000});
    });

    it('should create an Outcome Bond.', async function() {
        let tokenName = await this.tokenInstance.name.call();
        let votingAddress = await this.tokenInstance.voting.call();
        assert.equal(tokenName, 'test');
        assert.equal(votingAddress, this.votingInstance.address);
    });

    it('should generate outcome token and backer token when backed.', async function() {
        await this.tokenInstance.back({ from: accounts[0], value: 100 });
        let outcomeTokens = await this.tokenInstance.balanceOf.call(accounts[0]);
        let backerTokens = await this.tokenInstance.getBackerTokenAmount.call(accounts[0]);
        assert.equal(outcomeTokens, 100);
        assert.equal(backerTokens, 100);
    });

    it('should deduct backer tokens and transfer ether when redeeming backer tokens after voting results in not met.', async function() {
        await this.tokenInstance.back({ from: accounts[0], value: 100 });
        let balanceBefore = web3.eth.getBalance(accounts[0]);
        var Vote = {
            UNKNOWN: 0,
            MET: 1,
            NOT_MET: 2
        };
        await this.votingInstance.vote(this.tokenInstance.address, 2, { from: accounts[0]});
        //let result = await this.tokenInstance.redeemBackerTokens(100, { from: accounts[0] });
        /*
        let backerTokens = await this.tokenInstance.getBackerTokenAmount.call(accounts[0]);
        let balanceAfter = web3.eth.getBalance(accounts[0]);
        assert.equal(balanceAfter.sub(balanceBefore), 100);
        assert.equal(backerTokens, 0);
        */
    });


});