//*******************************************************************************************
// PROYECTO: Simple DeFi Yield Farming
// OBJETIVO: Implementar un proyecto DeFi simple usando Token Farm
// ARCHIVO : hardhat.config,ts
// Autor   : Ricardo Soria
//*******************************************************************************************
//
/*
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
};

export default config;

*/


import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

// Ve a https://infura.io, regístrate, crea una nueva clave API
// en su panel, y reemplázala por "KEY"
// const INFURA_API_KEY = "";

// Reemplaza esta clave privada por la clave privada de tu cuenta Sepolia
// Para exportar tu clave privada desde Metamask, abre Metamask y
// ve a Detalles de la Cuenta > Exportar Clave Privada
// Advertencia: NUNCA coloques Ether real en cuentas de prueba
const SEPOLIA_PRIVATE_KEY = "tuClave";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: `tuClave`,
      accounts: [SEPOLIA_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: "tuClave",
  },
};

export default config;

