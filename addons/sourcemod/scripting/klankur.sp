#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Anıl Can"
#define PLUGIN_VERSION "1.00"

#include < sourcemod >
#include < sdktools >
#include < store >
#include < multicolors >
#include < autoexecconfig >
#include < menu-stocks >
#include < cstrike >

#pragma newdecls required

ConVar clan_minkredi, clan_maxplayers, clan_invitewait;
int g_clanwrite[ MAXPLAYERS + 1 ], g_clanleader[ MAXPLAYERS + 1 ], g_clanmember[ MAXPLAYERS + 1 ], g_invent[ MAXPLAYERS + 1 ];
char g_clanname[ MAXPLAYERS + 1 ][ 64 ];
public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart( )
{
	AutoExecConfig_SetFile( "clan" );
	AutoExecConfig_SetCreateFile( true );
	
	RegConsoleCmd( "sm_klankur", Clan );
	RegConsoleCmd( "sm_klanyonet", ClanAdmin );
	
	clan_minkredi           = AutoExecConfig_CreateConVar( "clan_minkredi", "2000", "Klan kurmak icin gerekli olan minumum kredi" );
	clan_maxplayers         = AutoExecConfig_CreateConVar( "clan_maxplayers", "6", "Klan kurmak icin gerekli olan minumum kredi" );
	clan_invitewait         = AutoExecConfig_CreateConVar( "clan_invitewait", "60", "Oyuncuya davet yollandıktan sonra aynı oyuncuya ne kadar saniye sonra tekrar davet yollanabilceğini ayarlar" );
	
	AutoExecConfig_ExecuteFile( );
	AutoExecConfig_CleanFile( );
}
public void OnClientDisconnect( int client )
{
	if( g_clanleader[ client ] )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame( i ) && StrEqual( g_clanname[ client ], g_clanname[ i ], false ) )
			{
				CPrintToChat( i, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncu sunucudan çıktığı için klan silinmiştir.", client );
				Format( g_clanname[ i ], sizeof( g_clanname[ ] ), "" );
				CS_SetClientClanTag( i, "" );
			}
		}
	}
}
public void OnClientAuthorized( int client, const char[ ] auth )
{
	Format( g_clanname[ client ], sizeof( g_clanname[ ] ), "" );
	CS_SetClientClanTag( client, "" );
	g_clanleader[ client ] = 0;
	g_invent[ client ] = 0;
}
public Action Clan( int client, int args )
{
	if( !StrEqual( g_clanname[ client ], "", false )  )
	{
		CPrintToChat( client, "{darkred}Bir klanın içindeyken klan kuramazsın." );
		return Plugin_Handled;
	}
	if( Store_GetClientCredits( client ) < clan_minkredi.IntValue )
	{
		CPrintToChat( client, "{green}Bir klan kurmak için minimum {orange}[ {darkred}%i krediye {orange}] {green}sahip olmanız gerekiyor.", clan_minkredi.IntValue );
		return Plugin_Handled;
	}
	g_clanleader[ client ] = 1;
	ClanPanel( client );
	return Plugin_Handled;
}
public Action ClanPanel( int client )
{
	Menu menu = new Menu( ClanPanel_Handler );
	menu.SetTitle( "Klan Kurma Paneli" );
	if( StrEqual( g_clanname[ client ], "", false ) )
	{
		menu.AddItem( "1", "Klan İsmini Belirle" );
	}
	else
	{
		AddMenuItemFormat( menu, "2", ITEMDRAW_DISABLED, "Klan İsmi : %s", g_clanname[ client ] );
		menu.AddItem( "3", "Klan İsmini Kabul Et" );
		menu.AddItem( "4", "Klan İsmini Değiştir" );
	}
	menu.Display( client, MENU_TIME_FOREVER );
	return Plugin_Handled;
}
public int ClanPanel_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int num = StringToInt( info );
		switch( num )
		{
			case 1 :
			{
				g_clanwrite[ param1 ] = 1;
				CPrintToChat( param1, "{green}Lütfen klan ismini chate yazınız." );
			}
			case 3 :
			{
				ClanAdmin( param1, 1 );
			}
			case 4 :
			{
				g_clanwrite[ param1 ] = 1;
				CPrintToChat( param1, "{green}Lütfen klan ismini chate yazınız." );
			}
		}
	}
}
public Action OnClientSayCommand( int client, const char[ ] command, const char[ ] sArgs )
{
	if( g_clanwrite[ client ] )
	{
		Format( g_clanname[ client ], sizeof( g_clanname[ ] ), "[ %s ]", sArgs );
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( i != client && IsClientInGame( i ) && StrEqual( g_clanname[ client ], g_clanname[ i ], false ) )
			{
				CPrintToChat( client, "{green}Bu klan ismi mevcut lütfen başka bir isim deneyiniz" );
				return;
			}
		}
		CS_SetClientClanTag( client, g_clanname[ client ] );
		g_clanwrite[ client ] = 0;
		ClanPanel( client );
	}
}
public Action ClanAdmin( int client, int args )
{
	if( !g_clanleader[ client ] )
	{
		CPrintToChat( client, "Bu komut klan liderlerine özeldir" );
		return Plugin_Handled;
	}
	Menu menu = new Menu( ClanAdmin_Handler );
	menu.SetTitle( "%s Klanı Admin Paneli", g_clanname[ client ] );
	
	menu.AddItem( "1", "Klana Oyuncu Davet Et" );
	menu.AddItem( "2", "Klandan Oyuncu Çıkar" );
	menu.AddItem( "3", "Klandan Liderliğini Başka Bir Üyeye Devret" );
	menu.Display( client, MENU_TIME_FOREVER );
	return Plugin_Handled;
}
public int ClanAdmin_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int num = StringToInt( info );
		switch( num )
		{
			case 1 :
			{
				if( MaxClanMembers( param1 ) >= clan_maxplayers.IntValue )
				{
					CPrintToChat( param1, "{green}Bir klanda maksimum {orange}[ {darkred}%i oyuncu {orange}] {green}bulunabilir.", clan_maxplayers.IntValue );
					return;
				}
				g_clanmember[ param1 ] = 1;
				ListPlayer( param1 );
			}
			case 2 :
			{
				if( MaxClanMembers( param1 ) == 1 )
				{
					CPrintToChat( param1, "{darkred}Klanda oyuncu bulunmuyor." );
					return;
				}
				g_clanmember[ param1 ] = 2;
				ListPlayer( param1 );
			}
			case 3 :
			{
				if( MaxClanMembers( param1 ) == 1 )
				{
					CPrintToChat( param1, "{darkred}Klanda oyuncu bulunmuyor." );
					return;
				}
				g_clanmember[ param1 ] = 3;
				ListPlayer( param1 );
			}
		}
	}
}
public Action ListPlayer( int client )
{
	if( IsClientInGame( client ) )
	{
		Menu menu = new Menu( ListPlayer_Handler );
		menu.SetTitle( "Oyuncu Sec" );
		char list[ 64 ];
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame( i ) )
			{
				switch( g_clanmember[ client ] )
				{
					case 1 :
					{
						if( StrEqual( g_clanname[ i ], "", false ) && !g_invent[ i ] )
						{
							Format( list, sizeof( list ), "%i", i );
							AddMenuItemFormat( menu, list, _, "%N", i );
						}
					}
					case 2 :
					{
						if( StrEqual( g_clanname[ client ], g_clanname[ i ], false ) )
						{
							Format( list, sizeof( list ), "%i", i );
							AddMenuItemFormat( menu, list, _, "%N", i );
						}
					}
					case 3 :
					{
						if( StrEqual( g_clanname[ client ], g_clanname[ i ], false ) )
						{
							Format( list, sizeof( list ), "%i", i );
							AddMenuItemFormat( menu, list, _, "%N", i );
						}
					}
				}
			}
		}
		menu.Display( client, MENU_TIME_FOREVER );
	}
}
public int ListPlayer_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int target = StringToInt( info );
		if( target != 0 )
		{
			switch( g_clanmember[ param1 ] )
			{
				case 1 :
				{
					CPrintToChat( param1, "{green}Klan çağırma teklifi {orange}[ {darkblue}%N {orange}] {green}adlı oyuncuya yollandı.", target );
					ClanInventation( target, param1 );
					CreateTimer( clan_invitewait.FloatValue, WaitInvent, GetClientUserId( target ) );
					g_invent[ target ] = 1;
				}
				case 2 :
				{
					CPrintToChat( param1, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncu klandan atıldı.", target );
					CPrintToChat( target, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncu seni klandan atıldı.", param1 );
					Format( g_clanname[ target ], sizeof( g_clanname[ ] ), "" );
					CS_SetClientClanTag( target, "" );
				}
				case 3 :
				{
					CPrintToChat( param1, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncuya klan liderliğini devrettin.", target ); 
					CPrintToChat( target, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncu sana klan liderliğini devretti.", param1 ); 
					g_clanleader[ param1 ] = 0;
					g_clanleader[ target ] = 1;
				}
			}
		}
	}
}
public Action WaitInvent( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if( IsClientInGame( client ) && g_invent[ client ] ) g_invent[ client ] = 0;
}
public Action ClanInventation( int member, int leader )
{
	Menu menu = new Menu( ClanInventation_Handler );
	menu.SetTitle( "%N adlı oyuncu seni %s Klanına Katılmanı İstiyor", leader, g_clanname[ leader ] );
	
	char id[ 32 ];
	Format( id, sizeof( id ), "%i", leader );
	menu.AddItem( id, "Kabul Et" );
	menu.AddItem( "2", "Reddet" );
	menu.Display( member, 20 );
}
public int ClanInventation_Handler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char info[ 32 ];
		menu.GetItem( param2, info, sizeof( info ) );
		int leader = StringToInt( info );
		if( leader != 0 && param2 == 0 )
		{
			Format( g_clanname[ param1 ], sizeof( g_clanname[ ] ), "%s", g_clanname[ leader ] );
			CPrintToChat( param1, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncunun teklifini kabul ederek {purple}%s {green} klanına başarıyla katıldın.", leader, g_clanname[ param1 ] ); 
			CPrintToChat( leader, "{orange}[ {darkblue}%N {orange}] {green}adlı oyuncu teklifini kabul ederek {purple}%s {green} klanına başarıyla katıldı.", param1, g_clanname[ param1 ] );
			CPrintToChat( leader, "{green}Klana {orange}[ {purple}%i oyuncu{orange}] {green} daha davet edebilirsin.", clan_maxplayers.IntValue - MaxClanMembers( leader ) );
			CS_SetClientClanTag( param1, g_clanname[ param1 ] );
		}
	}
}
int MaxClanMembers( int client )
{
	int num;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ), StrEqual( g_clanname[ i ], g_clanname[ client ] ) )
		{
			num++;
		}
	}
	return num;
}