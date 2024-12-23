//*******************************************************************************************
// PROYECTO: Simple DeFi Yield Farming
// OBJETIVO: Implementar un proyecto DeFi simple usando Token Farm
// TEST    : TokenFarm.ts
// Autor   : Ricardo Soria
//*******************************************************************************************
//

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { ethers, utils } from 'hardhat';


describe('TokenFarm', function () {
  let owner: any;
  let otherAccount: any;
  let dappToken: any; 
  let lpToken: any; 
  let tokenFarm: any; 
  /// let dappToken: DappToken; 
  /// let lpToken: LPToken; 
  /// let tokenFarm: TokenFarm; 

  beforeEach(async function () {
    [owner, otherAccount] = await ethers.getSigners();

    const DappToken = await ethers.getContractFactory("DappToken");
    dappToken = await DappToken.deploy(owner.address);
    await dappToken.deployed();

    const LPToken = await ethers.getContractFactory("LPToken");
    lpToken = await LPToken.deploy(owner.address);
    await lpToken.deployed();

    const TokenFarm = await ethers.getContractFactory("TokenFarm");
    tokenFarm = await TokenFarm.deploy(dappToken.address, lpToken.address);
    await tokenFarm.deployed();

    // Mint tokens para las pruebas
    await dappToken.mint(owner.address, ethers.utils.parseEther("1000"));
    await lpToken.mint(owner.address, ethers.utils.parseEther("1000"));
  });

  it("Should deploy with the correct name", async function () {
    expect(await tokenFarm.name()).to.equal("Proportional Token Farm");
  });

  it("Should allow users to deposit LP tokens", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await lpToken.approve(tokenFarm.address, depositAmount);
    await tokenFarm.deposit(depositAmount);

    expect(await lpToken.balanceOf(tokenFarm.address)).to.equal(depositAmount);
    expect(await tokenFarm.stakingInfo(owner.address)).to.have.a.property('stakingBalance').to.equal(depositAmount);
  });

  it("Should allow users to withdraw LP tokens", async function () {
    const depositAmount = ethers.utils.parseEther("100");
    await lpToken.approve(tokenFarm.address, depositAmount);
    await tokenFarm.deposit(depositAmount);
  
    const withdrawAmount = ethers.utils.parseEther("100");
    await tokenFarm.withdraw();
  
    expect(await lpToken.balanceOf(owner.address)).to.be.gte(withdrawAmount);
    expect(await tokenFarm.stakingInfo(owner.address)).to.have.a.property('stakingBalance').to.equal(0);
  });



});