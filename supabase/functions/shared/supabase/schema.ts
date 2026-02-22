[38;5;142m[dotenvx@1.52.0] injecting env (9) from env/backend/local.env[39m
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      __drizzle_migrations: {
        Row: {
          created_at: number | null
          hash: string
          id: number
        }
        Insert: {
          created_at?: number | null
          hash: string
          id?: number
        }
        Update: {
          created_at?: number | null
          hash?: string
          id?: number
        }
        Relationships: []
      }
      context_summaries: {
        Row: {
          confirmed_facts: Json
          created_at: string
          id: string
          last_updated_turn: number
          plot_essentials: Json
          session_id: string
          short_term_summary: string
          updated_at: string
        }
        Insert: {
          confirmed_facts: Json
          created_at?: string
          id?: string
          last_updated_turn?: number
          plot_essentials: Json
          session_id: string
          short_term_summary?: string
          updated_at?: string
        }
        Update: {
          confirmed_facts?: Json
          created_at?: string
          id?: string
          last_updated_turn?: number
          plot_essentials?: Json
          session_id?: string
          short_term_summary?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "context_summaries_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: true
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      items: {
        Row: {
          created_at: string
          description: string
          id: string
          image_path: string | null
          is_equipped: boolean
          name: string
          quantity: number
          session_id: string
          type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string
          id?: string
          image_path?: string | null
          is_equipped?: boolean
          name: string
          quantity?: number
          session_id: string
          type?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          image_path?: string | null
          is_equipped?: boolean
          name?: string
          quantity?: number
          session_id?: string
          type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "items_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      npc_relationships: {
        Row: {
          affinity: number
          created_at: string
          debt: number
          fear: number
          flags: Json
          id: string
          npc_id: string
          trust: number
          updated_at: string
        }
        Insert: {
          affinity?: number
          created_at?: string
          debt?: number
          fear?: number
          flags: Json
          id?: string
          npc_id: string
          trust?: number
          updated_at?: string
        }
        Update: {
          affinity?: number
          created_at?: string
          debt?: number
          fear?: number
          flags?: Json
          id?: string
          npc_id?: string
          trust?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "npc_relationships_npc_id_npcs_id_fk"
            columns: ["npc_id"]
            isOneToOne: true
            referencedRelation: "npcs"
            referencedColumns: ["id"]
          },
        ]
      }
      npcs: {
        Row: {
          created_at: string
          emotion_images: Json | null
          goals: Json
          id: string
          image_path: string | null
          is_active: boolean
          location_x: number
          location_y: number
          name: string
          profile: Json
          scenario_id: string | null
          session_id: string | null
          state: Json
          updated_at: string
        }
        Insert: {
          created_at?: string
          emotion_images?: Json | null
          goals: Json
          id?: string
          image_path?: string | null
          is_active?: boolean
          location_x?: number
          location_y?: number
          name: string
          profile: Json
          scenario_id?: string | null
          session_id?: string | null
          state: Json
          updated_at?: string
        }
        Update: {
          created_at?: string
          emotion_images?: Json | null
          goals?: Json
          id?: string
          image_path?: string | null
          is_active?: boolean
          location_x?: number
          location_y?: number
          name?: string
          profile?: Json
          scenario_id?: string | null
          session_id?: string | null
          state?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "npcs_scenario_id_scenarios_id_fk"
            columns: ["scenario_id"]
            isOneToOne: false
            referencedRelation: "scenarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "npcs_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      objectives: {
        Row: {
          created_at: string
          description: string
          id: string
          session_id: string
          sort_order: number
          status: Database["public"]["Enums"]["objective_status"]
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string
          id?: string
          session_id: string
          sort_order?: number
          status?: Database["public"]["Enums"]["objective_status"]
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          session_id?: string
          sort_order?: number
          status?: Database["public"]["Enums"]["objective_status"]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "objectives_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      player_characters: {
        Row: {
          created_at: string
          id: string
          image_path: string | null
          location_x: number
          location_y: number
          name: string
          session_id: string
          stats: Json
          status_effects: Json
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          image_path?: string | null
          location_x?: number
          location_y?: number
          name: string
          session_id: string
          stats: Json
          status_effects: Json
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          image_path?: string | null
          location_x?: number
          location_y?: number
          name?: string
          session_id?: string
          stats?: Json
          status_effects?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "player_characters_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: true
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      scenarios: {
        Row: {
          created_at: string
          created_by: string | null
          description: string
          fail_conditions: Json
          id: string
          initial_state: Json
          is_public: boolean
          thumbnail_path: string | null
          title: string
          updated_at: string
          win_conditions: Json
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string
          fail_conditions: Json
          id?: string
          initial_state: Json
          is_public?: boolean
          thumbnail_path?: string | null
          title: string
          updated_at?: string
          win_conditions: Json
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string
          fail_conditions?: Json
          id?: string
          initial_state?: Json
          is_public?: boolean
          thumbnail_path?: string | null
          title?: string
          updated_at?: string
          win_conditions?: Json
        }
        Relationships: [
          {
            foreignKeyName: "scenarios_created_by_users_id_fk"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      scene_backgrounds: {
        Row: {
          created_at: string
          description: string
          id: string
          image_path: string | null
          location_name: string
          scenario_id: string | null
          session_id: string | null
        }
        Insert: {
          created_at?: string
          description?: string
          id?: string
          image_path?: string | null
          location_name: string
          scenario_id?: string | null
          session_id?: string | null
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          image_path?: string | null
          location_name?: string
          scenario_id?: string | null
          session_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "scene_backgrounds_scenario_id_scenarios_id_fk"
            columns: ["scenario_id"]
            isOneToOne: false
            referencedRelation: "scenarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "scene_backgrounds_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      sessions: {
        Row: {
          created_at: string
          current_state: Json
          current_turn_number: number
          ending_summary: string | null
          ending_type: string | null
          id: string
          scenario_id: string
          status: Database["public"]["Enums"]["session_status"]
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          current_state: Json
          current_turn_number?: number
          ending_summary?: string | null
          ending_type?: string | null
          id?: string
          scenario_id: string
          status?: Database["public"]["Enums"]["session_status"]
          title?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          current_state?: Json
          current_turn_number?: number
          ending_summary?: string | null
          ending_type?: string | null
          id?: string
          scenario_id?: string
          status?: Database["public"]["Enums"]["session_status"]
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "sessions_scenario_id_scenarios_id_fk"
            columns: ["scenario_id"]
            isOneToOne: false
            referencedRelation: "scenarios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_user_id_users_id_fk"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      turns: {
        Row: {
          created_at: string
          gm_decision_type: Database["public"]["Enums"]["gm_decision_type"]
          id: string
          input_text: string
          input_type: Database["public"]["Enums"]["input_type"]
          output: Json
          session_id: string
          turn_number: number
        }
        Insert: {
          created_at?: string
          gm_decision_type: Database["public"]["Enums"]["gm_decision_type"]
          id?: string
          input_text?: string
          input_type: Database["public"]["Enums"]["input_type"]
          output: Json
          session_id: string
          turn_number: number
        }
        Update: {
          created_at?: string
          gm_decision_type?: Database["public"]["Enums"]["gm_decision_type"]
          id?: string
          input_text?: string
          input_type?: Database["public"]["Enums"]["input_type"]
          output?: Json
          session_id?: string
          turn_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "turns_session_id_sessions_id_fk"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          account_name: string
          avatar_path: string | null
          created_at: string
          display_name: string
          id: string
          updated_at: string
        }
        Insert: {
          account_name: string
          avatar_path?: string | null
          created_at?: string
          display_name?: string
          id: string
          updated_at?: string
        }
        Update: {
          account_name?: string
          avatar_path?: string | null
          created_at?: string
          display_name?: string
          id?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      gm_decision_type: "narrate" | "choice" | "roll" | "clarify" | "repair"
      input_type:
        | "start"
        | "do"
        | "say"
        | "choice"
        | "roll_result"
        | "clarify_answer"
        | "system"
      objective_status: "active" | "completed" | "failed"
      session_status: "active" | "completed" | "abandoned"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      gm_decision_type: ["narrate", "choice", "roll", "clarify", "repair"],
      input_type: [
        "start",
        "do",
        "say",
        "choice",
        "roll_result",
        "clarify_answer",
        "system",
      ],
      objective_status: ["active", "completed", "failed"],
      session_status: ["active", "completed", "abandoned"],
    },
  },
} as const

