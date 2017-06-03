const MAX_PLAYERS_NUM = 32; 
#define cm(%0) ( sizeof(%0) - 1 ) 

#include <amxmodx> 

#pragma semicolon 1 

new const gWarnMessage[ ]    =    "You have been detected for spam, please don't try again or you will be punished!"; 
new const gBlockedWord[ ]    =    "You have been detected for using an illegal word!"; 

new const HUD_KICK_MESSAGE[ ]    =    "You are gonna be KICKED for chat-spamming!"; 
new const HUD_BAN_MESSAGE [ ]    =    "You are gonna be BANNED for chat-spamming!"; 


new gLastUserMessage[MAX_PLAYERS_NUM + 1][192]; 
new gBlockTimes[MAX_PLAYERS_NUM + 1]; 
new Float:g_Flooding[ MAX_PLAYERS_NUM + 1] = { 0.0, ... }; 
new g_Flood[ MAX_PLAYERS_NUM + 1] = {0, ...}; 
new Array:g_Stroke = Invalid_Array; 


new g_iPunishType, gUseLog, gBlockTimesCv, gFloodTime; 

public plugin_init( ) 
{ 
    register_plugin( "chat protection", "1.0", "craxor" ); 
  
    register_clcmd( "say", "hook_say" ); 
    register_clcmd( "say_team", "hook_say" ); 

    g_iPunishType = register_cvar( "acp_punish_type" , "1"  ); 
    gUseLog = register_cvar( "acp_log", "1" ); 
    gBlockTimesCv = register_cvar( "acp_warns", "3" ); 
    gFloodTime = register_cvar( "acp_flood_time", "0.75" ); 
} 


public client_putinserver( id )  
{ 
    gLastUserMessage[id][0] = EOS; 
    gBlockTimes[ id ] = 0; 
    g_Flood[ id ] = 0; 
    g_Flooding[ id ] = 0.0; 
} 

public hook_say( id ) 
{ 
    static Stroke[64], Size = 0; 
    new UserMessage[ 192 ], szUserName[ 32 ];  

    new Float:MAXCHAT = get_pcvar_float( gFloodTime ); 
    new Float:nexTime = get_gametime(); 

    read_args( UserMessage, cm( UserMessage ) ); 
    get_user_name( id, szUserName, cm( szUserName ) ); 


    /*    Here will detect for blocked words. */ 
    if( ArraySize(g_Stroke) ) 
    {     
        for (Size = 0; Size < ArraySize(g_Stroke); Size++) 
        { 
            ArrayGetString(g_Stroke, Size, Stroke, charsmax(Stroke)); 
         
            if (containi(UserMessage, Stroke) != -1) 
            { 
                client_print( id, print_chat, gBlockedWord ); 

                if( get_pcvar_num( gUseLog ) > 0 )  
                { 
                    new szBuffer[ 64 ]; 
                    formatex( szBuffer, 63, " (  [AMXX] %s: %s  )", szUserName, UserMessage ); 
         
                    log_to_file( "addons/amxmodx/logs/AdvancedChatProtectionLogs.txt", szBuffer ); 
                } 
         
                return PLUGIN_HANDLED; 
            } 

        } 
    } 

    /*    Here will check for the words if is the same the previous one OR if interval between message are too shourt    */ 
    if( equali( UserMessage, gLastUserMessage[id] ) || g_Flooding[id] > nexTime ) 
    {         
        client_print( id, print_chat, gWarnMessage ); 

        if( g_Flood[id] >= 3 ) 
        { 
            g_Flooding[id] = nexTime + MAXCHAT + 3.0; 
            gBlockTimes[ id ] = get_pcvar_num( gBlockTimesCv ) + 1; 
        } 
         
        g_Flood[id]++; 
        gBlockTimes[ id ]++; 

        if( gBlockTimes[ id ] > get_pcvar_num( gBlockTimesCv ) ) 
        { 
            show_motd( id, get_pcvar_num( g_iPunishType ) ? HUD_BAN_MESSAGE : HUD_KICK_MESSAGE ); 

            gBlockTimes[ id ] = 0; 
            clamp(get_pcvar_num( g_iPunishType ), 0, 1); 
         
            set_task( 4.2, "DoThePunish", id );     
        } 


        if( get_pcvar_num( gUseLog ) > 0 )  
        { 
            new szBuffer[ 64 ]; 
            formatex( szBuffer, 63, " (  [AMXX] %s: %s  )", szUserName, UserMessage ); 

            log_to_file( "addons/amxmodx/logs/AdvancedChatProtectionLogs.txt", szBuffer ); 
        } 
        return PLUGIN_HANDLED; 

         
    } 

    else 
    { 
        gBlockTimes[ id ] = 0; 
        g_Flooding[id] = nexTime + MAXCHAT; 

        if( UserMessage[0] != EOS )  
            copy( gLastUserMessage[id], charsmax( gLastUserMessage[] ), UserMessage ); 

        return PLUGIN_CONTINUE;     
    } 
    return PLUGIN_CONTINUE; 
} 

public plugin_cfg( ) 
{ 
    static File = 0, Buffer[64], Location[256]; 
     
    g_Stroke = ArrayCreate(64 /* maximum length */); 
     
    get_localinfo("amxx_configsdir", Location, charsmax(Location)); 
     
    add(Location, charsmax(Location), "/AcpWords.ini "); 
     
    if (!file_exists(Location)) 
    { 
        File = fopen(Location, "w+" /* write file */); 
         
        if (File) 
        { 
            fclose(File); 
        } 
    } 
     
    File = fopen(Location, "rt" /* read file as text */); 
     
    if (File) 
    { 
        while (!feof(File)) 
        { 
            fgets(File, Buffer, charsmax(Buffer)); 
             
            trim(Buffer); 
             
            if (!strlen(Buffer) || Buffer[0] == ';') 
            { 
                continue; 
            } 
             
            ArrayPushString(g_Stroke, Buffer); 
        } 
         
        fclose(File); 
    } 
} 


public DoThePunish( id ) 
{ 
    new szName[32]; 
    get_user_name( id, szName, charsmax( szName ) ); 

    switch( get_pcvar_num( g_iPunishType ) ) 
    { 
        case 0: server_cmd( "amx_kick %s" , szName ); 
        case 1: server_cmd( "amx_banip %s 999", szName); 
    } 
     
}  
