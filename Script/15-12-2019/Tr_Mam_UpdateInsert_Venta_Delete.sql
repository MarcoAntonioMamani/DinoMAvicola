USE [DBDinoM]
GO
/****** Object:  Trigger [dbo].[Tr_Mam_UpdateInsert_Venta_Delete]    Script Date: 15/12/2019 05:42:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[Tr_Mam_UpdateInsert_Venta_Delete] ON [dbo].[TV0011]
AFTER DELETE
AS
BEGIN

Declare 
		@tbnumi int,@tbtv1numi int, @tbty5prod int,@tbcmin decimal(18,2),@tbumin int, 
		@ingreso int, @salida int,@obs nvarchar(100),@cantAct decimal(18,2)
		,@maxid1 int,@fact date,@hact nvarchar(5),@uact nvarchar(10),@lcfpag date,@maxid2 int
		,@cantE decimal(18,2),@can decimal(18,2),@deposito int,@cliente nvarchar(100)=''
		,@tblote nvarchar(50),@tbfechavenc date
		set @ingreso = 1
		set @salida = 2
		set @lcfpag=GETDATE ()

		set @ingreso = 1
		set @salida = 2

--Declarando el cursor
declare MiCursor Cursor
	for Select a.tbnumi ,a.tbtv1numi ,a.tbty5prod ,a.tbcmin ,a.tbumin 
	,a.tblote ,a.tbfechaVenc  --, a.chhact, a.chuact, b.cpmov, b.cpdesc
				From deleted  a  --INNER JOIN TCI001 b ON a.chtmov=b.cpnumi
--Abrir el cursor
open MiCursor
-- Navegar
Fetch MiCursor into @tbnumi,@tbtv1numi,@tbty5prod,@tbcmin,@tbumin,@tblote,@tbfechavenc
while (@@FETCH_STATUS = 0)
begin
set @cliente =(select b.yddesc  from TV001 as a inner join TY004 as b on a.taclpr  =b.ydnumi and b.ydtip =1 and a.tanumi  =@tbtv1numi   )
	
	set @obs = CONCAT(' E ',' - Venta numiprod:',@tbty5prod,'|',@cliente )
		set @obs = CONCAT(@tbtv1numi,'-',@obs)
set @deposito =(Select b.abnumi   from TV001  as a,TA002 as b,TA001 as c where c.aata2depVenta  =b.abnumi 
and a.tanumi  =@tbtv1numi and a.taalm  =c.aanumi )
		
			set @obs = CONCAT(@tbnumi,'-',@obs)

			if (exists(select TI001.iccprod from TI001 where TI001.iccprod = convert(int, @tbty5prod)
			and TI001 .icalm =@deposito
			and  TI001.iclot =@tblote and TI001.icfven =@tbfechavenc  ))
			begin 	
				begin try
					begin tran Tr_UpdateTI001
						--Obtener la cantidad actual
						set @cantAct = (select TI001.iccven  from TI001 where TI001.iccprod  = convert(int, @tbty5prod)
						                                   and TI001.icalm =@deposito 
				and TI001.iclot =@tblote and TI001.icfven =@tbfechavenc )

						--Actualizar Saldo Inventario
						update TI001 
							set iccven  = @cantAct + @tbcmin 
							where TI001.iccprod  = CONVERT(int, @tbty5prod) and TI001.icalm  =@deposito 
							and TI001.iclot =@tblote and TI001.icfven =@tbfechavenc
			
						--Eliminar Movimiento
						--Detalle
						delete TI0021 where icibid in (select ibid from TI002 where ibiddc = @tbnumi and ibest=3 )
						--Cabecera
						delete TI002 where ibiddc = @tbnumi and ibest =3

					commit tran Tr_UpdateTI001
					print concat('Se actualizo el saldo del producto con codigo: ', @tbty5prod)
				end try
				begin catch
					rollback tran Tr_UpdateTI001
					print concat('No se pudo actualizo el saldo del producto con codigo: ', @tbty5prod)
				end catch
			end
			else
			begin
				begin try
					begin tran Tr_InsertTI001
						--set @can = (@can * @tcimov*-1)

						--Insertar Saldo Inventario
						--Insert into TI001 values(CONVERT(int, @cpcom), @can, 1)
			
						--Eliminar Movimiento
						--Detalle
						delete TI0021 where icibid in (select ibid from TI002 where ibiddc = @tbnumi and ibest =3 )
						--Cabecera
						delete TI002 where ibiddc = @tbnumi and ibest =3
					commit tran Tr_InsertTI001
					print concat('Se grabo el saldo del producto con codigo: ', @tbty5prod)
				end try
				begin catch
					rollback tran Tr_InsertTI001
					print concat('No se grabo el saldo del producto con codigo: ', @tbty5prod)
				end catch
			end


	Fetch MiCursor into @tbnumi,@tbtv1numi,@tbty5prod,@tbcmin,@tbumin,@tblote,@tbfechavenc
end

--Cerrar el Cursor
close MiCursor
--Liberar la memoria
deallocate MiCursor
END
