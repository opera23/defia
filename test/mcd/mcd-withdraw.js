const { expect } = require("chai");

const { getAssetInfo, ilks } = require('@defisaver/tokens');

const {
    getAddrFromRegistry,
    balanceOf,
    getProxy,
    redeploy,
    standardAmounts,
    MAX_UINT,
    MIN_VAULT_DAI_AMOUNT,
    WETH_ADDRESS
} = require('../utils');

const {
    fetchMakerAddresses,
    canGenerateDebt,
    getRatio,
} = require('../utils-mcd.js');

const {
    withdrawMcd,
    openVault,
    openMcd,
    supplyMcd,
} = require('../actions.js');

const BigNumber = hre.ethers.BigNumber;

describe("Mcd-Withdraw", function() {
    this.timeout(40000);

    let makerAddresses, senderAcc, proxy, mcdView;

    before(async () => {
        await redeploy('McdWithdraw');
        await redeploy('McdGenerate');
        mcdView = await redeploy('McdView');

        makerAddresses = await fetchMakerAddresses();

        senderAcc = (await hre.ethers.getSigners())[0];
        proxy = await getProxy(senderAcc.address);

    });

    for (let i = 0; i < ilks.length; ++i) {
        const ilkData = ilks[i];
        const joinAddr = ilkData.join;
        const tokenData = getAssetInfo(ilkData.asset);
        let vaultId;

        const withdrawAmount = (standardAmounts[tokenData.symbol] / 40).toString();

        it(`... should withdraw ${withdrawAmount} ${tokenData.symbol} from ${ilkData.ilkLabel} vault`, async () => {

            // skip uni tokens
            if (tokenData.symbol.indexOf("UNIV2") !== -1) {
                expect(true).to.be.true;
                return;
            }

            const canGenerate = await canGenerateDebt(ilkData);
            if (!canGenerate) {
                expect(true).to.be.true;
                return;
            }
            
            if (tokenData.symbol === 'ETH') {
                tokenData.address = WETH_ADDRESS;
            }

            vaultId = await openVault(
                makerAddresses,
                proxy,
                joinAddr,
                tokenData,
                (standardAmounts[tokenData.symbol] * 2).toString(),
                MIN_VAULT_DAI_AMOUNT
            );

            const to = senderAcc.address;
            const amountColl = ethers.utils.parseUnits(withdrawAmount, tokenData.decimals);

            const collBalanceBefore = await balanceOf(tokenData.address, to);

            await withdrawMcd(proxy, vaultId, amountColl, joinAddr, to);

            const collBalanceAfter = await balanceOf(tokenData.address, to);

            expect(collBalanceAfter).to.be.gt(collBalanceBefore);
        });

        it(`... should withdraw all coll ${tokenData.symbol} from ${ilkData.ilkLabel} vault`, async () => {

            // skip uni tokens
            if (tokenData.symbol.indexOf("UNIV2") !== -1) {
                expect(true).to.be.true;
                return;
            }

            const canGenerate = await canGenerateDebt(ilkData);
            if (!canGenerate) {
                expect(true).to.be.true;
                return;
            }
            
            if (tokenData.symbol === 'ETH') {
                tokenData.address = WETH_ADDRESS;
            }

            const amount = BigNumber.from(ethers.utils.parseUnits(standardAmounts[tokenData.symbol], tokenData.decimals));

            const to = senderAcc.address;
            const from = senderAcc.address;

            const vaultId = await openMcd(proxy, makerAddresses, joinAddr);
            await supplyMcd(proxy, vaultId, amount, tokenData.address, joinAddr, from);

            const collBalanceBefore = await balanceOf(tokenData.address, to);

            await withdrawMcd(proxy, vaultId, MAX_UINT, joinAddr, to);

            const collBalanceAfter = await balanceOf(tokenData.address, to);

            expect(collBalanceAfter).to.be.gt(collBalanceBefore);
        });
    }
});
