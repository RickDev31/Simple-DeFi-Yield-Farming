//*******************************************************************************************
// PROYECTO: Simple DeFi Yield Farming
// OBJETIVO: Implementar un proyecto DeFi simple usando Token Farm
// TEST    : LPToken.ts
// Autor   : Ricardo Soria
//*******************************************************************************************
//

import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('LPToken', function () {
  let owner;
  let otherAccount;
  let lpToken;

  beforeEach(async function () {
    [owner, otherAccount] = await ethers.getSigners();

    const LPToken = await ethers.getContractFactory('LPToken');
    lpToken = await LPToken.deploy(owner.address);
    await lpToken.deployed();
  });

  it('Should deploy with the correct name and symbol', async function () {
    expect(await lpToken.name()).to.equal('LP Token');
    expect(await lpToken.symbol()).to.equal('LPT');
  });

  it('Should have the correct initial supply', async function () {
    expect(await lpToken.totalSupply()).to.equal(0);
  });

  it('Should mint tokens correctly', async function () {
    const mintAmount = ethers.utils.parseEther('100');
    await lpToken.mint(otherAccount.address, mintAmount);

    expect(await lpToken.balanceOf(otherAccount.address)).to.equal(mintAmount);
    expect(await lpToken.totalSupply()).to.equal(mintAmount);
  });

  it('Should only allow the owner to mint tokens', async function () {
    const mintAmount = ethers.utils.parseEther('100');
    await expect(lpToken.connect(otherAccount).mint(otherAccount.address, mintAmount)).to.be.revertedWith("Ownable: caller is not the owner");
  });
});