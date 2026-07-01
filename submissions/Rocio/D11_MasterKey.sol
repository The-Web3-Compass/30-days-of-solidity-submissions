// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Ownable
 * @notice Contrato base que gestiona la propiedad del contrato,
 * implementando el control de acceso de 'onlyOwner'.
 */
contract Ownable {
    // La direccion del dueño actual. Se usa 'private' por seguridad.
    address private _owner;

    // Evento que se emite cuando la propiedad es transferida.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Se ejecuta al desplegar el contrato, estableciendo al creador como dueño.
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Retorna la direccion del dueño actual.
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Modificador que restringe la ejecucion de una funcion solo al dueño.
     */
    modifier onlyOwner() {
        // 'require' revierte la transaccion si la condicion es falsa.
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        // El guion bajo permite que el codigo de la funcion se ejecute aqui.
        _;
    }

    /// @notice Permite al dueño actual renunciar a la propiedad.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /// @notice Permite al dueño actual transferir la propiedad a una nueva direccion.
    /// @param newOwner La direccion que sera el nuevo dueño.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
