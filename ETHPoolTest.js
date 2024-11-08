const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ETHPool", function () {
    let ethPool, team, userA, userB;

    beforeEach(async () => {
        [team, userA, userB] = await ethers.getSigners();
        const ETHPool = await ethers.getContractFactory("ETHPool");
        ethPool = await ETHPool.deploy(team.address);
        await ethPool.deployed();
    });

    it("Only team should be able to deposit rewards", async function () {
        await expect(ethPool.connect(userA).depositRewards({ value: ethers.utils.parseEther("1") }))
            .to.be.revertedWith("Only team can perform this action");
    });

    it("Should allow users to deposit ETH", async function () {
        await ethPool.connect(userA).deposit({ value: ethers.utils.parseEther("1") });
        expect(await ethPool.deposits(userA.address)).to.equal(ethers.utils.parseEther("1"));
    });

    it("Should distribute rewards proportionally", async function () {
        // User A deposits 1 ETH
        await ethPool.connect(userA).deposit({ value: ethers.utils.parseEther("1") });
        // User B deposits 3 ETH
        await ethPool.connect(userB).deposit({ value: ethers.utils.parseEther("3") });
        
        // Team deposits 2 ETH as reward
        await ethPool.connect(team).depositRewards({ value: ethers.utils.parseEther("2") });

        // User A withdraws
        await ethPool.connect(userA).withdraw();
        const balanceA = await ethers.provider.getBalance(userA.address);
        expect(balanceA).to.be.closeTo(ethers.utils.parseEther("1.5"), ethers.utils.parseEther("0.01"));

        // User B withdraws
        await ethPool.connect(userB).withdraw();
        const balanceB = await ethers.provider.getBalance(userB.address);
        expect(balanceB).to.be.closeTo(ethers.utils.parseEther("4.5"), ethers.utils.parseEther("0.01"));
    });
});
