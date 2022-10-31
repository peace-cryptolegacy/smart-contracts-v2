import {BigNumber} from 'ethers';
import {deployments, ethers} from 'hardhat';
import {DynamicVaults} from '../../typechain/contracts/DynamicVaults';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {INACTIVITY_MAXIMUM} from '../utils/constants';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - succeed', function () {
  let DynamicVaults: DynamicVaults;
  let dynamicVaultId: BigNumber;
  let beneficiary1: User;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {deployedDynamicVaults, usedDynamicVaultId, testBeneficiary1} =
      await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    dynamicVaultId = usedDynamicVaultId;
    beneficiary1 = testBeneficiary1;
  });

  it('Calling the succeed function when the owner has not transcended should revert', async () => {
    await expect(
      beneficiary1.DynamicVaults.succeed(dynamicVaultId)
    ).to.be.revertedWith('T_NO_TRANSCENDENCE');
  });

  it('Calling the succeed function as someone that is not the claimer should revert', async () => {
    await expect(DynamicVaults.succeed(dynamicVaultId)).to.be.revertedWith(
      'T_UNAUTHORIZED'
    );
  });

  it('Calling the succeed function more than once should revert', async () => {
    await ethers.provider.send('evm_increaseTime', [
      INACTIVITY_MAXIMUM.toNumber(),
    ]);

    await ethers.provider.send('evm_mine', []);

    await expect(beneficiary1.DynamicVaults.succeed(dynamicVaultId)).to.emit(
      beneficiary1.DynamicVaults,
      'TestamentSucceeded'
    );

    await expect(
      beneficiary1.DynamicVaults.succeed(dynamicVaultId)
    ).to.be.revertedWith('T_SUCCEEDED');
  });
});
