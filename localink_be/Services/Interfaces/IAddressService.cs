using localink_be.Models.DTOs;

public interface IAddressService
{
    Task<AddressDto?> GetAddressByUserId(long userId);
}