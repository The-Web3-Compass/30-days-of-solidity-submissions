// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FitnessTracker
 * @notice Contrato para registrar entrenamientos y emitir eventos de logros
 * basados en metas acumuladas.
 */
contract FitnessTracker {

    /// @dev Define el formato de un registro de entrenamiento.
    struct WorkoutSession {
        string workoutType;        // Ej: "Running", "Lifting", "Yoga"
        uint durationMinutes;      // Duración en minutos
        uint caloriesBurned;       // Calorías quemadas
    }

    /// @dev Define el progreso acumulado de un usuario.
    struct UserProgress {
        WorkoutSession[] history;      // Historial de todas las sesiones
        uint totalWorkouts;            // Contador de entrenamientos totales
        uint totalDurationMinutes;     // Duracion total en minutos
    }

    // Mapea la dirección del usuario a su historial y progreso.
    mapping(address => UserProgress) public userProgress;

    /// @notice Se emite cada vez que un usuario registra un entrenamiento.
    event WorkoutLogged(
        address indexed user,          // El usuario que registro (indexed para busqueda)
        string workoutType,            // Tipo de entrenamiento
        uint durationMinutes,          // Duracion
        uint totalWorkoutsAccumulated  // Nuevo total de entrenamientos
    );

    /// @notice Se emite cuando un usuario alcanza una meta de fitness.
    event MilestoneReached(
        address indexed user,          // El usuario que alcanzo el hito (indexed)
        string indexed milestoneType,   // El tipo de meta: "WORKOUTS", "DURATION" (indexed)
        uint valueReached               // El valor alcanzado (ej: 500 minutos o 10 entrenamientos)
    );

    /// @notice Registra una nueva sesion de entrenamiento y actualiza el progreso.
    /// @param _type Tipo de entrenamiento (ej: "Run", "Lift").
    /// @param _duration Duracion en minutos.
    /// @param _calories Calorias quemadas.
    function logWorkout(
        string memory _type,
        uint _duration,
        uint _calories
    ) external {
        // 1. Crear el nuevo registro de sesion.
        // Usamos 'storage' para trabajar directamente con el mapping en la blockchain.
        UserProgress storage progress = userProgress[msg.sender];
        
        progress.history.push(
            WorkoutSession({
                workoutType: _type,
                durationMinutes: _duration,
                caloriesBurned: _calories
            })
        );

        // 2. Actualizar el progreso acumulado.
        progress.totalWorkouts++;
        progress.totalDurationMinutes += _duration;

        // 3. Emitir evento de registro
        emit WorkoutLogged(
            msg.sender,
            _type,
            _duration,
            progress.totalWorkouts
        );

        // 4. Verificar Logros
        checkMilestones(progress.totalWorkouts, progress.totalDurationMinutes);
    }

    /// @dev Verifica si se han alcanzado metas y emite eventos si es asi.
    function checkMilestones(uint _totalWorkouts, uint _totalDuration) internal {
        
        // Meta 1: 10 entrenamientos totales
        if (_totalWorkouts == 10) {
            emit MilestoneReached(
                msg.sender,
                "WORKOUTS_10", // Permite a la interfaz filtrar por este string
                _totalWorkouts
            );
        }
        
        // Meta 2: 500 minutos totales
        // (La lógica real debe evitar re-emitir el evento si ya se alcanzo,
        // pero simplificamos para mostrar el concepto de evento indexado).
        if (_totalDuration >= 500) {
            emit MilestoneReached(
                msg.sender,
                "DURATION_500", // Permite a la interfaz filtrar por este string
                _totalDuration
            );
        }
    }
}
