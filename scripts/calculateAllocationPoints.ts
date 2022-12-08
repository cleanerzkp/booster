interface IFarmParams {
  pid: number;
  name: string;
  apr: number;
  tvl: number;
}

interface IFarmConfig extends IFarmParams {
  emissionPerBlock: number;
  allocPoints: number;
}

interface IMasterChefConfig {
  farms: IFarmConfig[];
  kswapPerBlock: number;
  kswapRateToRegularFarm: number;
}

const farmList: IFarmParams[] = [
  {
    pid: 0,
    name: "USDC-BUSD",
    apr: 20,
    tvl: 110654,
  },
  {
    pid: 1,
    name: "WBNB-BUSD",
    apr: 45,
    tvl: 165071,
  },
  {
    pid: 2,
    name: "BTCB-BUSD",
    apr: 25,
    tvl: 52205,
  },
  {
    pid: 3,
    name: "ETH-BUSD",
    apr: 30,
    tvl: 56388,
  },
  {
    pid: 4,
    name: "XRP-BUSD",
    apr: 30,
    tvl: 31132,
  },
  {
    pid: 5,
    name: "USDT-WBNB",
    apr: 34,
    tvl: 62185,
  },
  {
    pid: 6,
    name: "ADA-WBNB",
    apr: 20,
    tvl: 14909,
  },
  {
    pid: 7,
    name: "WBNB-LINK",
    apr: 20,
    tvl: 4016,
  },
  {
    pid: 8,
    name: "DOT-WBNB",
    apr: 20,
    tvl: 17045,
  },
  {
    pid: 9,
    name: "ADA-BUSD",
    apr: 20,
    tvl: 13771,
  },
  {
    pid: 10,
    name: "BUSD-LINK",
    apr: 20,
    tvl: 21205,
  },
  {
    pid: 11,
    name: "DOT-BUSD",
    apr: 20,
    tvl: 26644,
  },
  {
    pid: 12,
    name: "KSWAP-BUSD",
    apr: 100,
    tvl: 24087,
  },
  {
    pid: 13,
    name: "KSWAP-WBNB",
    apr: 100,
    tvl: 21038,
  },
];

const TOTAL_POINTS = 1e10;
const KSWAP_RATE_TOTAL_PRECISION = 1e12;
const KSWAP_PER_BLOCK = 4e19;
const kswapRateToRegularFarm = 312821341;
/*const kswapPerBlock =
  (KSWAP_PER_BLOCK * kswapRateToRegularFarm) / KSWAP_RATE_TOTAL_PRECISION;/**/

function getUpdatedFarmConfiguration(
  price: number,
  farms: IFarmParams[]
): IMasterChefConfig {
  let kswapPerBlock = 0;

  const updatedFarms = farms
    .map((farm: IFarmParams): IFarmConfig => {
      const emissionPerYear = (farm.tvl * farm.apr) / (price * 100);
      const emissionPerBlock = (emissionPerYear / (365 * 24 * 60 * 20)) * 1e18;
      kswapPerBlock += emissionPerBlock;

      return {
        pid: farm.pid,
        name: farm.name,
        apr: farm.apr,
        tvl: farm.tvl,
        emissionPerBlock: emissionPerBlock,
        allocPoints: 0,
      };
    })
    .map((farm: IFarmConfig): IFarmConfig => {
      farm.allocPoints = Math.round(
        (farm.emissionPerBlock * TOTAL_POINTS) / kswapPerBlock
      );
      return farm;
    });

  /**
   * kswapPerBlock = (KSWAP_PER_BLOCK * kswapRateToRegularFarm) / KSWAP_RATE_TOTAL_PRECISION;
   * k = (b * r) / p
   * r = k * p / b
   * kswapRateToRegularFarm = ;
   */

  return {
    farms: updatedFarms,
    kswapPerBlock: kswapPerBlock,
    kswapRateToRegularFarm:
      (kswapPerBlock * KSWAP_RATE_TOTAL_PRECISION) / KSWAP_PER_BLOCK,
  };
}

async function main() {
  //const price = 1.794933208563345595946677041358868;
  const price = 1.7;

  const masterChefConfig = getUpdatedFarmConfiguration(price, farmList);

  console.table(
    masterChefConfig.farms.map((farm: IFarmConfig) => {
      return {
        pid: farm.pid,
        name: farm.name,
        apr: farm.apr,
        tvl: farm.tvl,
        emissionPerBlock: farm.emissionPerBlock,
        emissionPerBlockETH: farm.emissionPerBlock / 1e18,
        allocPoints: farm.allocPoints,
      };
    })
  );

  console.table({
    kswapPerBlock: masterChefConfig.kswapPerBlock,
    kswapRateToRegularFarm: masterChefConfig.kswapRateToRegularFarm,
  });

  console.table({
    totalAllocationPoints: masterChefConfig.farms.reduce(
      (accumulator, farm) => accumulator + farm.allocPoints,
      0
    ),
    totalEmissionPerBlock: masterChefConfig.farms.reduce(
      (accumulator, farm) => accumulator + farm.emissionPerBlock,
      0
    ),
    totalEmissionPerBlockETH:
      masterChefConfig.farms.reduce(
        (accumulator, farm) => accumulator + farm.emissionPerBlock,
        0
      ) / 1e18,
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
