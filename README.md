# nor_flash_generic

Generic NOR flash abstraction layer for bare-metal Ada applications.

## Overview

`nor_flash_generic` provides a hardware-independent NOR flash memory interface for embedded systems. It separates control and data operations through distinct generic packages, enabling flexible instantiation patterns for SPI/QSPI NOR flash devices.

## Features

- Hardware-agnostic NOR flash abstraction
- Support for SPI, Dual-SPI, and Quad-SPI transfer modes
- Separate control and data operation packages
- Combined interface package for convenience
- JEDEC ID validation
- Erase operations (sector, block, chip)
- Page program and fast-read operations
- Power management (sleep/wake)
- Software reset
- Automatic QE bit programming for QSPI mode

## Architecture

The package is organized into three layers:

- **`Nor_Flash_Types`** - Common types, configuration records, and exceptions
- **`Nor_Flash_Control`** - Device initialization, erase, reset, and power management
- **`Nor_Flash_Data`** - Page program and read operations
- **`Nor_Flash_Interface`** - Combined control and data interface

## API

### Nor_Flash_Types

```ada
package Nor_Flash_Types is
   Nor_Error       : exception;
   Nor_Unsupported : exception;
   Nor_Timeout     : exception;

   subtype Nor_Address is MT.UInt32;
   subtype Nor_Size    is MT.UInt32;

   type Page_Index   is new MT.UInt32;
   type Sector_Index is new MT.UInt32;
   type Block_Index  is new MT.UInt32;
   type Page_Size    is new MT.UInt16;
...
   type Transfer_Mode is (Single, Dual, Quad);
   type Erase_Granularity is (Chip, Sector_4K, Block_32K, Block_64K);
...
   type Nor_Config is record
      Total_Size  : Nor_Size;
      Page_Size   : Nor_Flash_Types.Page_Size;
      Erase_Gran  : Erase_Granularity;
      Transfer    : Transfer_Mode;
      Protection  : Protection_State;
      Id          : Nor_Id;
   end record;
end Nor_Flash_Types;
```

### Nor_Flash_Interface

```ada
generic
   type Device is limited private;
   
   with procedure Bus_Command
     (Dev : in out Device;
      Cmd :        MT.UInt8);
   
   with procedure Bus_Command_Address
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Addr :        Nor_Flash_Types.Nor_Address);
   
   with procedure Bus_Read_Status
     (Dev    : in out Device;
      Status :    out MT.UInt8);
   
   with procedure Bus_Command_Read
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Data :    out Storage_Array);
   
   with procedure Bus_Write
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :        Storage_Array);
   
   with procedure Bus_Read
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :    out Storage_Array);
   
   with function Driver_Config
     (Dev : Device) return Nor_Flash_Types.Nor_Config;
   
   with function Driver_Read_SR2
     (Dev : Device) return MT.UInt8;
   
   with procedure Driver_Write_Status
     (Dev : in out Device;
      SR1 :        MT.UInt8;
      SR2 :        MT.UInt8);

package Nor_Flash_Interface is
   procedure Open (Dev : in out Device);
   procedure Close (Dev : in out Device);
   procedure Reset (Dev : in out Device);
   
   procedure Erase_Sector (Dev : in out Device; Idx : Nor_Flash_Types.Sector_Index);
   procedure Erase_Block (Dev : in out Device; Idx : Nor_Flash_Types.Block_Index);
   procedure Erase_Chip (Dev : in out Device);
   
   procedure Write_Page (Dev : in out Device; Addr : Nor_Flash_Types.Nor_Address; Buf : Storage_Array);
   procedure Read (Dev : in out Device; Addr : Nor_Flash_Types.Nor_Address; Buf : out Storage_Array);
end Nor_Flash_Interface;
```

## Usage

### 1. Implement Hardware Driver Layer

```ada
package W25Q128_Dev is
   type Device is limited private;
   
   function Make_Device (SPI_Bus : access SPI_Interface.Device) return Device;
   
   procedure Bus_Command
     (Dev : in out Device;
      Cmd :        MT.UInt8);
   
   procedure Bus_Command_Address
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Addr :        Nor_Flash_Types.Nor_Address);
   
   procedure Bus_Read_Status
     (Dev    : in out Device;
      Status :    out MT.UInt8);
   
   procedure Bus_Command_Read
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Data :    out Storage_Array);
   
   procedure Bus_Write
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :        Storage_Array);
   
   procedure Bus_Read
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :    out Storage_Array);
   
   function Driver_Config (Dev : Device) return Nor_Flash_Types.Nor_Config;
   function Driver_Read_SR2 (Dev : Device) return MT.UInt8;
   
   procedure Driver_Write_Status
     (Dev : in out Device;
      SR1 :        MT.UInt8;
      SR2 :        MT.UInt8);
end W25Q128_Dev;
```

### 2. Implement Device Configuration

```ada
function Driver_Config (Dev : Device) return Nor_Flash_Types.Nor_Config is
begin
   return (Total_Size  => 16 * 1024 * 1024,
           Page_Size   => 256,
           Erase_Gran  => Nor_Flash_Types.Sector_4K,
           Transfer    => Nor_Flash_Types.Single,
           Protection  => Nor_Flash_Types.Unprotected,
           Id          => (Manufacturer => 16#EF#,
                          Memory_Type  => 16#40#,
                          Capacity     => 16#18#));
end Driver_Config;
```

### 3. Instantiate Nor_Flash_Interface

```ada
with Nor_Flash_Interface;
with W25Q128_Dev;

package Nor_Flash_Dev is new Nor_Flash_Interface
  (Device               => W25Q128_Dev.Device,
   Bus_Command          => W25Q128_Dev.Bus_Command,
   Bus_Command_Address  => W25Q128_Dev.Bus_Command_Address,
   Bus_Read_Status      => W25Q128_Dev.Bus_Read_Status,
   Bus_Command_Read     => W25Q128_Dev.Bus_Command_Read,
   Bus_Write            => W25Q128_Dev.Bus_Write,
   Bus_Read             => W25Q128_Dev.Bus_Read,
   Driver_Config        => W25Q128_Dev.Driver_Config,
   Driver_Read_SR2      => W25Q128_Dev.Driver_Read_SR2,
   Driver_Write_Status  => W25Q128_Dev.Driver_Write_Status);
```

### 4. Use NOR Flash

```ada
Flash_Device : aliased W25Q128_Dev.Device := W25Q128_Dev.Make_Device (SPI_1'Access);

Nor_Flash_Dev.Open (Flash_Device);
Nor_Flash_Dev.Erase_Sector (Flash_Device, 0);
Nor_Flash_Dev.Write_Page (Flash_Device, 16#0000#, Data);
Nor_Flash_Dev.Read (Flash_Device, 16#0000#, Read_Back);
Nor_Flash_Dev.Close (Flash_Device);
```

## Design Rationale

### Separate Control and Data Packages

Splitting initialization/erase and read/write operations allows different access patterns: configuration and erase operations during setup, data operations in application loops.

### Limited Private Device Type

The `Device` type is limited private, preventing accidental copying and ensuring single ownership of hardware resources.

### Generic Bus Operations

Bus operation procedures are generic formals, allowing the same NOR flash logic to work over SPI, QSPI, or any custom transport layer.

### JEDEC ID Validation

The `Open` procedure validates the device JEDEC ID against the expected configuration, catching wiring errors or wrong device types at runtime.

### Layered Architecture

The separation between generic interface, device driver, board-level facade, and device object enables portability and clear separation of concerns.

## Limitations

- Currently supports 24-bit addressing (devices up to 128 Mbit)
- Dummy cycle count for fast read is hardcoded to 1

## Integration

Add to your `alire.toml`:

```toml
[[depends-on]]
nor_flash_generic = "^0.1.0"
```

## Dependencies

- `machine_types` - Provides `MT.UInt8`, `MT.UInt16`, `MT.UInt32` types

## License

MIT OR Apache-2.0 WITH LLVM-exception
