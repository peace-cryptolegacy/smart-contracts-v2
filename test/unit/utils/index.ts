import {BigNumber} from 'ethers';

import {DynamicVaults} from '../../../typechain';
import {setupUser} from '../../utils';
import {DYNAMIC_VAULT_ID, INACTIVITY_MAXIMUM} from '../../utils/constants';
import {Deployer, Mocks, User} from '../../utils/types';

//Functional setup for Position Contract Tests :
//Deploying Contracts, mocking return values, returning users
export const setupTestContracts = async (
  deployer: Deployer,
  mocks: Mocks,
  users: ({address: string} & Deployer)[]
): Promise<{
  usedDynamicVaultId: BigNumber;
  deployedDynamicVaults: DynamicVaults;
  testGovernance: User;
  testDynamicVaultOwner: User;
  testBeneficiary1: User;
  testBeneficiary2: User;
  testUser1: User;
  testExploiter: User;
}> => {
  const deployedDynamicVaults = await deployer.DynamicVaultsF.deploy();

  // setup users
  const testGovernance = await setupUser(users[1].address, {
    DynamicVaults: deployedDynamicVaults,
  });

  const testDynamicVaultOwner = await setupUser(users[2].address, {
    DynamicVaults: deployedDynamicVaults,
  });

  const testBeneficiary1 = await setupUser(users[3].address, {
    DynamicVaults: deployedDynamicVaults,
  });

  const testBeneficiary2 = await setupUser(users[4].address, {
    DynamicVaults: deployedDynamicVaults,
  });

  const testUser1 = await setupUser(users[5].address, {
    DynamicVaults: deployedDynamicVaults,
  });

  const testExploiter = await setupUser(users[6].address, {
    DynamicVaults: deployedDynamicVaults,
  });

  // setup mocks
  await mocks.TestToken.mock.transfer.returns(true);
  await mocks.TestToken.mock.transferFrom.returns(true);

  // create testament
  const usedDynamicVaultId = DYNAMIC_VAULT_ID;

  await testDynamicVaultOwner.DynamicVaults.createTestament(
    usedDynamicVaultId,
    testBeneficiary1.address,
    INACTIVITY_MAXIMUM,
    [
      {
        name: 'test',
        address_: testBeneficiary1.address,
        inheritancePercentage: 0,
      },
    ]
  );

  return {
    usedDynamicVaultId,
    deployedDynamicVaults,
    testGovernance,
    testDynamicVaultOwner,
    testBeneficiary1,
    testBeneficiary2,
    testUser1,
    testExploiter,
  };
};
