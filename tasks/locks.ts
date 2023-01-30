import { task } from "hardhat/config";
import { TokenLocker } from "../typechain-types";

const accounts = [
  "0x02512befcc919f9a5dad6c9b4022b91d9982c443",
  "0x02968341f7a519a446afbdaf4bd439e5f27b612a",
  "0x03a944a570f918553e48d82f1ca28a63552c704e",
  "0x05ca54398e5a47bee9f1aea1ec7225ac812937f5",
  "0x0c53b052760d02edd069c3bd0e320bf2834dee71",
  "0x0d4851601216a8347402b36687085e52e3c51cd1",
  "0x1bf358d2bef71e395e74b3a55225d6df80b1cd8c",
  "0x1c3016721a6661d48e3e85896a343b6c0248d23c",
  "0x1eb12271bb895e87944c88365cb90d2b86602976",
  "0x246ae80c663d4c5fd122ad12ff30f053acc26147",
  "0x252d6f678b89c6f549e003aed82a3b07c1e2c68a",
  "0x28e690b76a30ff912af2c5bbe90390f6bcb4d4dc",
  "0x299566277cac0238cccc83ef3270b7872613ed22",
  "0x2ce38803bf39dd09e072255b19ad3912bb799603",
  "0x2e976f0633ef80771ab2cd93100ffee0fb6dabf5",
  "0x40b4edb12dbca810f5599570dd52128acf47d6c1",
  "0x47f6222b274f46af3cd12c0522aac37d0b4524cd",
  "0x49148dfad27457c917554a3f075d42a7c6be2b7f",
  "0x4c4b0ac8cea92dd2291ad8a204b573b8971c5d22",
  "0x4d6b611b0d48226239a30dc25fb088da611e0972",
  "0x4dc8f53f70eadec2d1866566da06e3e994f13df5",
  "0x500e331c594612056dd3bb204d3c434bf957c55c",
  "0x50cef7d7a4be2495fe86d13e6d51a52e97b55807",
  "0x50d026aa7ebf21696eba319c9c0722f1ebfa3433",
  "0x5672c4a8eae5c4e1b6a5e1341ddb34c311c49a0e",
  "0x5e4542ad851ceb9ff561a542bde08c774e25e6be",
  "0x61baf9247340b788ae9392344e059cd760ee8c2e",
  "0x63d16fe701739b3f242c7eb4f1dcb9602e6fecef",
  "0x64a051459a7c1941f4276578067f220cd9dcf3c4",
  "0x711804d6fdf79dcc9ea36442b4b810237bbcad32",
  "0x7a76af427a094491045febec066c4a7a8eebc207",
  "0x7b3fc8884f69a30bea47013961e06c54fc003ad3",
  "0x7ca256f198215414e637d595f281968c2d24c4e7",
  "0x7de3544c4e8afd07fcb1e4fa3ea5f86d8e24ab36",
  "0x7eb99e397782e41bdd2231c149c754750820c233",
  "0x81472802fdf8fc91c2d4626b8032bfd8037e828e",
  "0x8ab4d73558415c4844c19161e39c0a3fd6b7c230",
  "0x8d5aa0bcf33d2269ec300fd7b1285032197f2c98",
  "0x8dc4ff736a2ce3ce3a5b27a23448c1cb31264487",
  "0x9008bd14e066f68fb4839242e906b910a44d9fb7",
  "0x92f76921421831b4db5c778d13f50c6b949d1153",
  "0x93835cade634a247316cb99f2fcae83e7fc7c2ff",
  "0x950214ea266e72dadbe13e0ded04618206afc41b",
  "0x98d8febd603ae744b2256e07b9e4e0889bbd25ef",
  "0x9918ae644cc21ce678e2dc98fb1e07526aa66e62",
  "0x9a85a373f07d223294f34155f49ec8345c7d78e2",
  "0xa3f8fa1ed2d8d3801e5cce43777cb4e5b39ea7bf",
  "0xaac2dd9bf63bd3474d08966cbaab12edc0e46463",
  "0xad8785a9eaa9da8e0822b2c9c47ca18b6c060bcd",
  "0xc91612048c15425028170f303426cd534b96fe60",
  "0xca94e791eee754dd0df39c66de79e5c3e50b2d34",
  "0xcb14c487761067d13c70eb5b018a846f10d959da",
  "0xd2cd9e22b8dd71fe1876175310ff95d80d88d173",
  "0xd31e9a3e1321c89bb6b400eae70a507e49c1f4be",
  "0xd58a0157ac8514f18ff62af271592ded5f086615",
  "0xddd924f42acd939b7e63f44009a17b855e1c60a1",
  "0xdf9528770963538330d7f04f338edcf50f645f93",
  "0xdff4af4de0ddbaad161ec38d7adbb7f9c72aa1ac",
  "0xe6462bdbd5d8f411b8dbea6764a73fa6b157243f",
  "0xe877174dec97c052c0e352f8b079ee486a85edc5",
  "0xe910796e639b1b64c478d23d6592395af6c4d37b",
  "0xe96e30a7cb064bef302751afc8597d436f0cb717",
  "0xea8598a3311be1125792a46ccbeeef95eebc96ee",
  "0xf08563f5966dd245e4ba51cbb010a09fd67f620e",
  "0xf46a28d097a757d84b85fee640b47c07a0666b4e",
  "0xf6c9ebd49c948888b921f150b03cf63a7ab58a3a",
  "0xf75c1bb2815ff6cfa902a66355d29a4fac8453c2",
  "0xfa2ff0cf93cf8ff58e283804d68c23d7d71b53d9",
  "0xfad6abe14b4feb4e100b7b0594e83bb918c0bbf1",
  "0xff99afcb2fc368bb97fa13c9d0ec89da979f5a00",
];

const durations = [86400 * 30, 86400 * 365];

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

task("locks", "Prints the list of token locks", async (taskArgs, hre) => {
  const { ethers, deployments } = hre;

  const locker = (await ethers.getContractAt(
    "TokenLocker",
    (
      await deployments.get("TokenLocker")
    ).address
  )) as TokenLocker;

  for (let index = 0; index < accounts.length; index++) {
    await delay(1000);
    const account = accounts[index];

    console.log("Account (" + index + "): " + account);

    const balance = await locker.balanceOf(account);
    console.log("voKSWAP Balance: " + ethers.utils.formatEther(balance));

    const userInfos = await locker["getUserInfo(address)"](account);

    console.log("Old locks:");
    for (let uIndex = 0; uIndex < userInfos.length; uIndex++) {
      const userInfo = userInfos[uIndex];

      const lockedAt = new Date(userInfo.lockedAt * 1000);
      const expiresAt = new Date(
        (userInfo.lockedAt + userInfo.duration) * 1000
      );

      console.log(
        account +
          ";" +
          ethers.utils.formatEther(userInfo.amount) +
          ";0;" +
          userInfo.duration / 60 / 60 / 24 +
          " days" +
          ";" +
          (lockedAt.toLocaleDateString() +
            " " +
            lockedAt.toLocaleTimeString()) +
          ";" +
          (expiresAt.toLocaleDateString() +
            " " +
            expiresAt.toLocaleTimeString())
      );
    }

    console.log("New locks:");
    const locks = await locker.getLocks([account, account], durations);
    for (let dIndex = 0; dIndex < durations.length; dIndex++) {
      const lock = locks[dIndex];

      if (lock.amount.eq(0)) continue;

      const lockedAt = new Date(lock.lockedAt * 1000);
      const expiresAt = new Date(lock.expiresAt * 1000);
      console.log(
        account +
          ";" +
          ethers.utils.formatEther(lock.amount) +
          ";" +
          ethers.utils.formatEther(lock.reward) +
          ";" +
          lock.duration / 60 / 60 / 24 +
          " days" +
          ";" +
          lockedAt.toLocaleDateString() +
          " " +
          lockedAt.toLocaleTimeString() +
          ";" +
          expiresAt.toLocaleDateString() +
          " " +
          expiresAt.toLocaleTimeString()
      );
    }
    console.log("");
    console.log("");
  }
});

task(
  "locks:export:old",
  "Exports the list of old token locks",
  async (taskArgs, hre) => {
    const { ethers } = hre;

    const locker = (await ethers.getContract("TokenLocker")) as TokenLocker;

    for (let index = 0; index < accounts.length; index++) {
      const account = accounts[index];

      const locks = await locker["getUserInfo(address)"](account);

      for (let lIndex = 0; lIndex < locks.length; lIndex++) {
        const lockedAt = new Date(locks[lIndex].lockedAt * 1000);
        const expiresAt = new Date(
          (locks[lIndex].lockedAt + locks[lIndex].duration) * 1000
        );
        console.log(
          account +
            ";" +
            ethers.utils.formatEther(locks[lIndex].amount) +
            ";" +
            locks[lIndex].duration / 60 / 60 / 24 +
            " days" +
            ";" +
            lockedAt.toISOString() +
            ";" +
            expiresAt.toISOString()
        );
      }
    }
  }
);

task(
  "locks:export:new",
  "Exports the list of new token locks",
  async (taskArgs, hre) => {
    const { ethers, deployments } = hre;

    const locker = (await ethers.getContractAt(
      "TokenLocker",
      (
        await deployments.get("TokenLocker")
      ).address
    )) as TokenLocker;

    for (let index = 0; index < accounts.length; index++) {
      const account = accounts[index];

      for (let dIndex = 0; dIndex < durations.length; dIndex++) {
        const duration = durations[dIndex];
        const lock = await locker.getLock(account, duration);

        if (lock.amount.eq(0)) continue;

        const lockedAt = new Date(lock.lockedAt * 1000);
        const expiresAt = new Date(lock.expiresAt * 1000);
        console.log(
          account +
            ";" +
            ethers.utils.formatEther(lock.amount) +
            ";" +
            lock.duration / 60 / 60 / 24 +
            " days" +
            ";" +
            lockedAt.toLocaleDateString() +
            " " +
            lockedAt.toLocaleTimeString() +
            ";" +
            expiresAt.toLocaleDateString() +
            " " +
            expiresAt.toLocaleTimeString()
        );
      }
    }
  }
);

task(
  "locks:export:balances",
  "Exports the list of token locker balances",
  async (taskArgs, hre) => {
    const { ethers, deployments } = hre;

    const locker = (await ethers.getContractAt(
      "TokenLocker",
      (
        await deployments.get("TokenLocker")
      ).address
    )) as TokenLocker;

    for (let index = 0; index < accounts.length; index++) {
      const account = accounts[index];

      const balance = await locker.balanceOf(account);
      console.log(account + ";" + ethers.utils.formatEther(balance));
    }
  }
);

task("locks:migrate", "Migrate the locks", async (taskArgs, hre) => {
  const { ethers, deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const locker = (await ethers.getContractAt(
    "TokenLocker",
    (
      await deployments.get("TokenLocker")
    ).address
  )) as TokenLocker;

  const cLocker = locker.connect(await ethers.getSigner(deployer));
  const tx = await cLocker.migrate(accounts);
  console.log(tx);
});
