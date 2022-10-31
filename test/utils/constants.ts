import {BigNumber, constants} from 'ethers';
import {TestamentCreationParams} from './types';

export const DYNAMIC_VAULT_ID = BigNumber.from(0);
export const ONE_DAY = BigNumber.from(86400);
export const INACTIVITY_MAXIMUM = ONE_DAY.mul(BigNumber.from(365)); // one year
export const TESTAMENT_CREATION_PARAMS: TestamentCreationParams = [
  BigNumber.from(1),
  constants.AddressZero,
  INACTIVITY_MAXIMUM,
  [
    {
      name: 'test',
      address_: constants.AddressZero,
      inheritancePercentage: BigNumber.from(0),
    },
  ],
];