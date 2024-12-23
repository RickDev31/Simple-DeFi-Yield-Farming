//*******************************************************************************************
// PROYECTO: Simple DeFi Yield Farming
// OBJETIVO: Implementar un proyecto DeFi simple usando Token Farm
// CONTRATO: TokenFarm.sol
// Autor   : Ricardo Soria
//*******************************************************************************************
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DappToken.sol";
import "./LPToken.sol";

/*===========================================================================================
 * @title Proportional Token Farm
 * @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
 */
contract TokenFarm {
    //
    // Variables de estado
    //
    string public name = "Proportional Token Farm";
    address public owner;
    DappToken public dappToken;
    LPToken public lpToken;

    uint256 public constant REWARD_PER_BLOCK = 1e18; // Recompensa por bloque (total para todos los usuarios)
    uint256 public totalStakingBalance;  // Total de tokens en staking
    uint256 public commissionPercentage; // Porcentaje de comisión configurable

    address[] public stakers;

    //
    // Struct{} información staking usuario para omitir los mappings
    //
    mapping(address => StakingInfo) public stakingInfo;
    struct StakingInfo {
        uint256 stakingBalance;
        uint256 checkpoint;
        uint256 pendingRewards;
        bool hasStaked;
        bool isStaking;
    }

    /* par cambiar los nomnres den la estructura
    struct StakingInfo {
    uint256 userStakingBalance; // Balance de staking del usuario
    uint256 lastRewardBlock; // Último bloque en el que se calcularon las recompensas

    */

    //
    // Eventos
    //
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalRewards);
    event CommissionCharged(address indexed user, uint256 amount, uint256 blockNumber);


    //
    // Modifier
    //
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Constructor
    constructor(DappToken _dappToken, LPToken _lpToken) {
        // Configurar las instancias de los contratos de DappToken y LPToken.
        dappToken = _dappToken;
        lpToken = _lpToken;

        // Configurar al owner del contrato como el creador de este contrato.
        owner = msg.sender;

        // establecer valor de la comision por retiro de recompensas
        // siempre se cobra una comision, pero no puede ser el 100%
        require(_commissionPercentage > 0 && _commissionPercentage < 100, "Invalid commission percentage");
        commissionPercentage = _commissionPercentage;
    }

    /****************************************************************************************
     * @notice Deposita tokens LP para staking.
     * @param _amount Cantidad de tokens LP a depositar.
     */
    function deposit(uint256 _amount) external {
        // Verificar que _amount sea mayor a 0.
        require(_amount > 0, "The amount must be greater than 0");

        // Transferir tokens LP del usuario a este contrato.
        lpToken.transferFrom(msg.sender, address(this), _amount);

        // Actualizar las recompensas pendientes antes de modificar el balance.
        distributeRewards(msg.sender);

        // Actualizar la información de staking del usuario.
        StakingInfo storage userInfo = stakingInfo[msg.sender];
        userInfo.stakingBalance += _amount;
        userInfo.isStaking = true;

        // Incrementar el balance total de staking.
        totalStakingBalance += _amount;

        // Si el usuario nunca había hecho staking, inicializar los datos.
        if (!userInfo.hasStaked) {
            stakers.push(msg.sender);
            userInfo.hasStaked = true;
        }

        // Si el checkpoint del usuario está vacío (es decir, 0), inicializarlo.
        if (userInfo.checkpoint == 0) {
            userInfo.checkpoint = block.number;
        }

        // Emitir un evento de depósito.
        emit Deposit(msg.sender, _amount);
    }

    /****************************************************************************************
     * @notice Retira todos los tokens LP en staking.
     */
    function withdraw() external {
        // Obtener la información del usuario
        StakingInfo storage userInfo = stakingInfo[msg.sender];

        // Verificar que el usuario está haciendo staking
        require(userInfo.isStaking, "You are not staking");
        // Si se busca ahorrar gas los 2 requires se podrian juntar en uno solo
        // Verificar que el usuario está haciendo staking y tiene un balance mayor a 0
        // require(userInfo.isStaking && userInfo.stakingBalance > 0, "You are not staking or have insufficient balance");

        // Obtener el balance de staking del usuario
        uint256 amount = userInfo.stakingBalance;

        // Verificar que el balance de staking sea mayor a 0
        require(amount > 0, "Insufficient staking balance");

        // Calcular y distribuir las recompensas pendientes
        distributeRewards(msg.sender);

        // Restablecer el estado del usuario
        userInfo.stakingBalance = 0;
        userInfo.isStaking = false;
        userInfo.checkpoint = 0;

        // Reducir el balance total de staking
        totalStakingBalance -= amount;

        // Transferir los tokens LP al usuario
        lpToken.transfer(msg.sender, amount);

        // Emitir un evento retiro
        emit Withdraw(msg.sender, amount);
    }

    /****************************************************************************************
     * @notice Reclama recompensas pendientes.
     */
    function claimRewards() external {
        // Obtener la información del usuario
        StakingInfo storage userInfo = stakingInfo[msg.sender];

        // Obtener el monto de recompensas pendientes del usuario
        uint256 pendingAmount = userInfo.pendingRewards;

        // Verificar que el monto de recompensas pendientes sea mayor a 0
        require(pendingAmount > 0, "No pending rewards");

        // Calcular la comisión
        uint256 commission = (pendingAmount * commissionPercentage) / 100;

        // Restablecer las recompensas pendientes del usuario a 0
        userInfo.pendingRewards = 0;

        // Acunar y transferir las recompensas al usuario
        dappToken.mint(msg.sender, pendingAmount - commission);

        // Emitir un evento de reclamo de recompensas y comisiones
        emit RewardsClaimed(msg.sender, pendingAmount - commission);
        emit CommissionCharged(msg.sender, commission, block.number);
    }

    /****************************************************************************************
     * @notice Distribuye recompensas a todos los usuarios en staking.
     */
    /// distributeRewardsAll()
    ///--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9---
    /// añadimos a la funcion el modificador onlyOwner como medida de seguridad esencial
    /// para proteger la integridad del contrato y solo pueda ser ejecutada por el
    /// propietario del contrato y asi garantizar que las distribuciones de recompensas se
    /// realicen de manera justa y transparente.
    /// Se emite el evento RewardsDistributed() desde esta función para indicar que se ha
    /// completado una distribución global de recompensas, pero tambien podria moverse
    /// dentro de la funcion ditributeRewards() pero se generaria un exceso de eventos.
    ///--1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9---
    ///
    function distributeRewardsAll() external onlyOwner {
        // Iterar sobre todos los usuarios en staking
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            // Verificar si el usuario está haciendo staking
            if (stakingInfo[staker].isStaking) {
                distributeRewards(staker);
            }
        }
        // Emitir un evento indicando que las recompensas han sido distribuidas
        emit RewardsDistributed(block.number);
    }

    /****************************************************************************************
     * @notice Calcula y distribuye las recompensas proporcionalmente al staking total.
     * @dev La función toma en cuenta el porcentaje de tokens que cada usuario tiene en staking con respecto
     *      al total de tokens en staking (`totalStakingBalance`).
     *
     **/
    function distributeRewards(address beneficiary) private {
        StakingInfo storage userInfo = stakingInfo[beneficiary];

        uint256 scale = 1e18;

        // Obtener el último checkpoint del usuario desde checkpoints.
        uint256 lastCheckpoint = userInfo.checkpoint;

        // Verificar que el número de bloque actual sea mayor al checkpoint y que totalStakingBalance sea mayor a 0.
 
        // Calcular la cantidad de bloques transcurridos desde el último checkpoint.
        if (block.number <= lastCheckpoint) {
            return; // No hay nuevos bloques, no se calculan recompensas
        }

        // Verificar que el balance total de staking sea mayor a 0
        if (totalStakingBalance == 0) {
            return; // No hay balance total para distribuir recompensas
        }

        // Calcular la cantidad de bloques transcurridos desde el último checkpoint.
        uint256 blocksSinceLastCheckpoint = block.number - lastCheckpoint;

        // Calcular las recompensas
        // la proporción del staking del usuario en relación al total staking
        // las recompensas del usuario multiplicando la proporción por REWARD_PER_BLOCK y los bloques transcurridos.
        uint256 numerator = blocksSinceLastCheckpoint *
            REWARD_PER_BLOCK *
            userInfo.stakingBalance *
            scale;
        uint256 reward = (numerator / totalStakingBalance) / scale;

        // Actualizar el checkpoint del usuario al bloque actual.
        userInfo.checkpoint = block.number;

        // Actualizar las recompensas pendientes del usuario en pendingRewards.
        userInfo.pendingRewards += reward;
    }
}
