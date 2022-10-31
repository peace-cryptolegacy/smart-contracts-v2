import {MockContract} from '@ethereum-waffle/mock-contract';
import {BigNumber} from 'ethers';

import {DynamicVaults, DynamicVaults__factory} from '../../typechain';
import {Types} from '../../typechain/contracts/DynamicVaults';

export type TestamentCreationParams = [
  dynamicVaultId: BigNumber,
  claimant: string,
  inactivityMaximum: BigNumber,
  Beneficiaries: Types.BeneficiaryStruct[]
];

export type Deployer = {
  DynamicVaults: DynamicVaults;
  DynamicVaultsF: DynamicVaults__factory;
};

export type Mocks = {
  TestToken: MockContract;
  DynamicVaults: MockContract;
};

export type User = {
  address: string;
  DynamicVault: DynamicVaults | MockContract;
};
