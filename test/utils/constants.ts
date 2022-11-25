import {BigNumber, constants} from 'ethers';
import {parseEther} from 'ethers/lib/utils';
import {TestamentCreationParams} from './types';

export const ONE_DAY = BigNumber.from(86400);
export const INACTIVITY_MAXIMUM = ONE_DAY.mul(BigNumber.from(365)); // one year
export const TESTAMENT_CREATION_PARAMS: TestamentCreationParams = [
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
export const APPROVE_AMOUNT = parseEther('1000');
export const ESTABLISHMENT_FEE_RATE = parseEther('0.025');
