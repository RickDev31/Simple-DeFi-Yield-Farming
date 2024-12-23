//*******************************************************************************************
// PROYECTO: Simple DeFi Yield Farming
// OBJETIVO: Implementar un proyecto DeFi simple usando Token Farm
// TEST    : DappToken.ts
// Autor   : Ricardo Soria
//*******************************************************************************************
//

import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('DappToken', function () {
  let owner;
  let otherAccount;
  let dappToken;

  beforeEach(async function () {
    [owner, otherAccount] = await ethers.getSigners();

    const DappToken = await ethers.getContractFactory('DappToken');
    dappToken = await DappToken.deploy(owner.address);
    await dappToken.deployed();
  });

  it('Should deploy with the correct name and symbol', async function () {
    expect(await dappToken.name()).to.equal('Dapp Token');
    expect(await dappToken.symbol()).to.equal('DAPP');
  });

  it('Should have the correct initial supply', async function () {
    expect(await dappToken.totalSupply()).to.equal(0); 
  });

  it('Should mint tokens correctly', async function () {
    const mintAmount = ethers.utils.parseEther('100');
    await dappToken.mint(otherAccount.address, mintAmount);

    expect(await dappToken.balanceOf(otherAccount.address)).to.equal(mintAmount);
    expect(await dappToken.totalSupply()).to.equal(mintAmount);
  });

  it('Should only allow the owner to mint tokens', async function () {
    const mintAmount = ethers.utils.parseEther('100');
    await expect(dappToken.connect(otherAccount).mint(otherAccount.address, mintAmount)).to.be.revertedWith('Ownable: caller is not the owner'); 
  });
});