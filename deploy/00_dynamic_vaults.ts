import debugModule from 'debug';
import {deployments} from 'hardhat';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DynamicVaults} from '../typechain';
import {ESTABLISHMENT_FEE_RATE} from '../utils/constants';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const log = debugModule('deploy-setup');
  log.enabled = true;

  const {deploy, catchUnknownSigner} = deployments;
  const {ethers, getNamedAccounts} = hre;

  // keep ts support on hre members
  const {governance} = await getNamedAccounts();

  log('Deployer = Governance: ' + governance);

  // Deploy test token
  // The contract is deployed directly from governance since the DynamicVault contract is Ownable. This saves on an
  // extra transaction to transfer ownership.
  await catchUnknownSigner(
    deploy('DynamicVaults', {
      from: governance,
      proxy: {
        proxyContract: 'OpenZeppelinTransparentProxy',
        owner: governance,
        execute: {
          init: {
            methodName: 'initialize',
            args: [ESTABLISHMENT_FEE_RATE],
          },
        },
      },
    })
  );

  const DynamicVaults = <DynamicVaults>(
    await ethers.getContract('DynamicVaults')
  );

  // Print all contracts info pretty
  log('DynamicVaults proxy address at: ' + DynamicVaults.address);
};
export default func;
func.tags = ['all', 'dynamicVaults', 'test'];
