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
  await deploy('ExampleContract', {
    from: deployer,
  });

  const ExampleContract = await ethers.getContract('ExampleContract');

  // Print all contracts info pretty
  log('ExampleContract address: ' + ExampleContract.address);
};
export default func;
func.tags = ['all', 'ExampleContract', 'test'];
