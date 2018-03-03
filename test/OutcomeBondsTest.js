
var OutcomeBondToken = artifacts.require('OutcomeBondToken.sol');
var Voting = artifacts.require('AnybodyDecidesNoCap.sol');

contract('OutcomeBondToken', function(accounts) {
    var Vote = {
        UNKNOWN: 0,
        MET: 1,
        NOT_MET: 2
    };

    beforeEach(async function() {
        this.votingInstance = await Voting.new({from: accounts[0]});
        this.tokenInstance = await OutcomeBondToken.new('test', this.votingInstance.address, {from: accounts[0]}); 
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

    it('should deduct backer tokens and transfer ether when redeeming backer tokens after voting results in NOT_MET.', async function() {
        var gasUsedInWei = 0;
        var gasPrice = 10**11;
        await this.tokenInstance.back({ from: accounts[1], value: 100 });
        let balanceBefore = web3.eth.getBalance(accounts[1]);
        await this.votingInstance.vote(this.tokenInstance.address, Vote.NOT_MET, { from: accounts[0]});
        await this.tokenInstance.redeemBackerTokens(100, { from: accounts[1], gasPrice: gasPrice }).then(function(result) {
            gasUsedInWei += result.receipt.cumulativeGasUsed*gasPrice;
        });
        let backerTokens = await this.tokenInstance.getBackerTokenAmount.call(accounts[1]);
        let balanceAfter = web3.eth.getBalance(accounts[1]);
        assert.equal(balanceAfter.add(gasUsedInWei).sub(balanceBefore).toString(), '100');
        assert.equal(backerTokens, 0);
    });

    it('should redeem outcome tokens after voting results in MET.', async function() {
        await this.tokenInstance.back({ from: accounts[0], value: 100 });
        await this.votingInstance.vote(this.tokenInstance.address, Vote.MET, { from: accounts[0]});
        await this.tokenInstance.redeemBackerTokens(100, { from: accounts[0] })
    });


});