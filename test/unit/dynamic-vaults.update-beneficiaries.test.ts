import {deployments, ethers} from 'hardhat';
import {DynamicVaults} from '../../typechain/contracts/DynamicVaults';
import {FDAI} from '../../typechain/contracts/mocks/FDAI';
import {expect} from '../helpers/chai-setup';
import {setupFixture, setupUser} from '../utils';
import {APPROVE_AMOUNT} from '../utils/constants';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - update beneficiaries', function () {
  let DynamicVaults: DynamicVaults;
  let owner: string;
  let dynamicVaultOwner: User, beneficiary1: User, exploiter: User;
  let FDAI: FDAI;
  let newBeneficiaries = [
    [''],
    ['0x0000000000000000000000000000000000000000'],
    [0],
  ];
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {
      deployedDynamicVaults,
      testDynamicVaultOwner,
      testBeneficiary1,
      testExploiter,
    } = await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    owner = testDynamicVaultOwner.address;
    beneficiary1 = testBeneficiary1;
    exploiter = testExploiter;

    const deployedFDAI = await deployer.FDAIF.deploy();
    FDAI = deployedFDAI;
    dynamicVaultOwner = await setupUser(users[2].address, {
      DynamicVaults: deployedDynamicVaults,
      FDAI: deployedFDAI,
    });
    FDAI.mint(dynamicVaultOwner.address, APPROVE_AMOUNT);
  });

  it('Calling update beneficiaries with the address zero should revert', async () => {
    await expect(
      dynamicVaultOwner.DynamicVaults.updateBeneficiaries(
        [''],
        [ethers.constants.AddressZero],
        [0],
        [0]
      )
    ).to.be.revertedWith('T_ADDRESS_ZERO');

    const beneficiaries = (
      await DynamicVaults.dynamicVaults(dynamicVaultOwner.address)
    ).testament.beneficiaries;

    expect(beneficiaries[0].name).to.equal('test');
  });

  it('Calling the update beneficiaries should update the values', async () => {
    await expect(
      dynamicVaultOwner.DynamicVaults.updateBeneficiaries(
        ['Jeremy'],
        [beneficiary1.address],
        [100],
        [0]
      )
    ).to.emit(dynamicVaultOwner.DynamicVaults, 'BeneficiariesUpdated');

    const beneficiaries = (
      await DynamicVaults.dynamicVaults(dynamicVaultOwner.address)
    ).testament.beneficiaries;

    expect(beneficiaries[0].name).to.equal('Jeremy');
  });

  it('Adding a new beneficiary should work', async () => {
    await expect(
      dynamicVaultOwner.DynamicVaults.updateBeneficiaries(
        ['Jeremy'],
        [beneficiary1.address],
        [100],
        [1]
      )
    ).to.emit(dynamicVaultOwner.DynamicVaults, 'BeneficiariesUpdated');

    const beneficiaries = (
      await DynamicVaults.dynamicVaults(dynamicVaultOwner.address)
    ).testament.beneficiaries;

    expect(beneficiaries[1].name).to.equal('Jeremy');
  });
});
