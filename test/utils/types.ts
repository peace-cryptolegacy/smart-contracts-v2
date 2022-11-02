import {MockContract} from '@ethereum-waffle/mock-contract';
import {BigNumber} from 'ethers';

import {DynamicVaults, DynamicVaults__factory, FDAI} from '../../typechain';
import {Types} from '../../typechain/contracts/DynamicVaults';
import {FDAI__factory} from '../../typechain/factories/contracts/mocks/FDAI__factory';

export type TestamentCreationParams = [
  dynamicVaultId: BigNumber,
  claimant: string,
  inactivityMaximum: BigNumber,
  Beneficiaries: Types.BeneficiaryStruct[]
];

export type Deployer = {
  DynamicVaults: DynamicVaults;
  DynamicVaultsF: DynamicVaults__factory;
  FDAIF: FDAI__factory;
};

export type Mocks = {
  TestToken: MockContract;
  DynamicVaults: MockContract;
};

export type User = {
  address: string;
  DynamicVaults: DynamicVaults | MockContract;
  FDAI?: FDAI | MockContract;
};
