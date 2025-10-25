const { expect } = require("chai");

describe("FortKnoxVault", function () {
  let owner, alice, bob;
  let Gold, gold, Vault, vault;
  const initial = ethers.utils.parseUnits("1000", 18);

  beforeEach(async function () {
    [owner, alice, bob] = await ethers.getSigners();
    Gold = await ethers.getContractFactory("MockERC20");
    gold = await Gold.deploy("Gold", "GLD");
    await gold.deployed();
    await gold.mint(alice.address, initial);
    await gold.mint(bob.address, initial);
    Vault = await ethers.getContractFactory("FortKnoxVault");
    vault = await Vault.deploy(gold.address);
    await vault.deployed();
  });

  it("deposit and withdraw flow", async function () {
    const amount = ethers.utils.parseUnits("100", 18);
    await gold.connect(alice).approve(vault.address, amount);
    await vault.connect(alice).deposit(amount);
    expect(await vault.balanceOf(alice.address)).to.equal(amount);
    await vault.connect(alice).withdraw(amount);
    expect(await vault.balanceOf(alice.address)).to.equal(0);
    const aliceBalance = await gold.balanceOf(alice.address);
    expect(aliceBalance).to.equal(initial);
  });

  it("withdrawAll works", async function () {
    const amount = ethers.utils.parseUnits("50", 18);
    await gold.connect(bob).approve(vault.address, amount);
    await vault.connect(bob).deposit(amount);
    expect(await vault.balanceOf(bob.address)).to.equal(amount);
    await vault.connect(bob).withdrawAll();
    expect(await vault.balanceOf(bob.address)).to.equal(0);
  });

  it("onlyOwner can pause", async function () {
    await expect(vault.connect(alice).setPaused(true)).to.be.reverted;
    await vault.connect(owner).setPaused(true);
    await gold.connect(alice).approve(vault.address, ethers.utils.parseUnits("1", 18));
    await expect(vault.connect(alice).deposit(ethers.utils.parseUnits("1", 18))).to.be.reverted;
  });
});
