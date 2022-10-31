import debugModule from 'debug';
import {deployments} from 'hardhat';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const log = debugModule('deploy-setup');
  log.enabled = true;

  const {deploy} = deployments;
  const {ethers, getNamedAccounts} = hre;

  // keep ts support on hre members
  const {deployer} = await getNamedAccounts();

  log('Deployer: ' + deployer);

  // Deploy test token
  await deploy('DynamicVaults', {
    from: deployer,
  });

  const DynamicVaults = await ethers.getContract('DynamicVaults');

  // Print all contracts info pretty
  log('DynamicVaults address: ' + DynamicVaults.address);
};
export default func;
func.tags = ['all', 'dynamicVaults', 'test'];
