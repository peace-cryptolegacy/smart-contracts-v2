import {deployments} from 'hardhat';
import {DynamicVaults} from '../../typechain';
import {expect} from '../helpers/chai-setup';
import {setupFixture} from '../utils';
import {User} from '../utils/types';
import {setupTestContracts} from './utils/index';

const setup = deployments.createFixture(async () => {
  return setupFixture('all');
});

describe('DynamicVaults - Pause ', function () {
  let DynamicVaults: DynamicVaults;
  let exploiter: User, governance: User;
  beforeEach(async () => {
    const {deployer, mocks, users} = await setup();

    const {deployedDynamicVaults, testExploiter, testGovernance} =
      await setupTestContracts(deployer, mocks, users);
    DynamicVaults = deployedDynamicVaults;
    exploiter = testExploiter;
    governance = testGovernance;
  });

  it('Pausing the contract without being the owner should revert', async () => {
    await expect(exploiter.DynamicVaults.pause()).to.be.revertedWith(
      'Ownable: caller is not the owner'
    );
  });

  it('Unpausing the contract without being the owner should revert', async () => {
    await expect(exploiter.DynamicVaults.unpause()).to.be.revertedWith(
      'Ownable: caller is not the owner'
    );
  });

  it('Pausing the contract while it was already paused should revert', async function () {
    await expect(governance.DynamicVaults.pause()).to.emit(
      governance.DynamicVaults,
      'Paused'
    );
    await expect(governance.DynamicVaults.pause()).to.be.revertedWith(
      'Pausable: paused'
    );
  });

  it('Unpausing the contract while it was already unpaused should revert', async function () {
    await expect(governance.DynamicVaults.unpause()).to.be.revertedWith(
      'Pausable: not paused'
    );
  });

  it('Pausing the contract while it is unpaused should update the pause status', async function () {
    await expect(governance.DynamicVaults.pause()).to.emit(
      governance.DynamicVaults,
      'Paused'
    );
    expect(await governance.DynamicVaults.paused()).to.be.true;
  });

  it('Unpausing the contract while it is paused should update the pause status', async function () {
    await expect(governance.DynamicVaults.pause()).to.emit(
      governance.DynamicVaults,
      'Paused'
    );
    await expect(governance.DynamicVaults.unpause()).to.emit(
      governance.DynamicVaults,
      'Unpaused'
    );
    expect(await governance.DynamicVaults.paused()).to.be.false;
  });
});
