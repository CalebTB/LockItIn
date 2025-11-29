# API Endpoints

```swift
// APIClient.swift
import Foundation
import Supabase

class APIClient {
    static let shared = APIClient()
    
    private let supabase: SupabaseClient
    private let baseURL = "https://your-project.supabase.co"
    private let apiKey = "your-anon-key"
    
    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: baseURL)!,
            supabaseKey: apiKey
        )
    }
    
    // MARK: - Auth
    
    func signUp(email: String, password: String, fullName: String) async throws -> User {
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        guard let userId = authResponse.user?.id else {
            throw APIError.authFailed
        }
        
        // Create user profile
        let profile: [String: Any] = [
            "id": userId.uuidString,
            "email": email,
            "full_name": fullName,
            "username": email.components(separatedBy: "@").first ?? ""
        ]
        
        try await supabase.database
            .from("users")
            .insert(values: profile)
            .execute()
        
        return try await fetchUser(id: userId.uuidString)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authResponse = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        guard let userId = authResponse.user?.id else {
            throw APIError.authFailed
        }
        
        return try await fetchUser(id: userId.uuidString)
    }
    
    // MARK: - Users
    
    func fetchUser(id: String) async throws -> User {
        let response = try await supabase.database
            .from("users")
            .select()
            .eq(column: "id", value: id)
            .single()
            .execute()
        
        return try JSONDecoder().decode(User.self, from: response.data)
    }
    
    // MARK: - Groups
    
    func fetchGroups(for userId: String) async throws -> [Group] {
        let response = try await supabase.database
            .from("group_members")
            .select("""
                group_id,
                groups (
                    id,
                    name,
                    description,
                    emoji,
                    created_by,
                    created_at
                )
            """)
            .eq(column: "user_id", value: userId)
            .is(column: "left_at", value: "null")
            .execute()
        
        // Parse nested response
        let data = response.data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode([GroupMembershipResponse].self, from: data)
            .map { $0.group }
    }
    
    func createGroup(name: String, emoji: String, createdBy: String) async throws -> Group {
        let groupData: [String: Any] = [
            "name": name,
            "emoji": emoji,
            "created_by": createdBy
        ]
        
        let response = try await supabase.database
            .from("groups")
            .insert(values: groupData)
            .single()
            .execute()
        
        let group = try JSONDecoder().decode(Group.self, from: response.data)
        
        // Add creator as admin
        let memberData: [String: Any] = [
            "group_id": group.id.uuidString,
            "user_id": createdBy,
            "role": "admin"
        ]
        
        try await supabase.database
            .from("group_members")
            .insert(values: memberData)
            .execute()
        
        return group
    }
    
    // MARK: - Event Proposals
    
    func createProposal(
        title: String,
        groupId: String,
        createdBy: String,
        timeOptions: [ProposalTimeOption]
    ) async throws -> EventProposal {
        // Create proposal
        let proposalData: [String: Any] = [
            "title": title,
            "group_id": groupId,
            "created_by": createdBy,
            "status": "voting"
        ]
        
        let proposalResponse = try await supabase.database
            .from("event_proposals")
            .insert(values: proposalData)
            .single()
            .execute()
        
        let proposal = try JSONDecoder().decode(EventProposal.self, from: proposalResponse.data)
        
        // Create time options
        for (index, option) in timeOptions.enumerated() {
            let optionData: [String: Any] = [
                "proposal_id": proposal.id.uuidString,
                "start_time": ISO8601DateFormatter().string(from: option.startTime),
                "end_time": ISO8601DateFormatter().string(from: option.endTime),
                "option_order": index
            ]
            
            try await supabase.database
                .from("proposal_time_options")
                .insert(values: optionData)
                .execute()
        }
        
        // Send notifications to group members
        try await notifyGroupMembers(groupId: groupId, proposalId: proposal.id.uuidString)
        
        return proposal
    }
    
    func voteOnProposal(
        proposalId: String,
        timeOptionId: String,
        userId: String,
        response: VoteResponse
    ) async throws {
        let voteData: [String: Any] = [
            "proposal_id": proposalId,
            "time_option_id": timeOptionId,
            "user_id": userId,
            "response": response.rawValue
        ]
        
        // Upsert vote (insert or update)
        try await supabase.database
            .from("proposal_votes")
            .upsert(values: voteData)
            .execute()
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToProposal(id: String, onChange: @escaping (EventProposal) -> Void) -> RealtimeChannel {
        let channel = supabase.realtime.channel("proposal:\(id)")
        
        channel.on(.postgresChanges(
            event: .update,
            schema: "public",
            table: "event_proposals",
            filter: "id=eq.\(id)"
        )) { payload in
            if let proposal = try? JSONDecoder().decode(EventProposal.self, from: payload.new) {
                onChange(proposal)
            }
        }
        
        channel.subscribe()
        return channel
    }
    
    // MARK: - Helpers
    
    private func notifyGroupMembers(groupId: String, proposalId: String) async throws {
        // Fetch group members
        let response = try await supabase.database
            .from("group_members")
            .select("user_id")
            .eq(column: "group_id", value: groupId)
            .execute()
        
        let members = try JSONDecoder().decode([GroupMember].self, from: response.data)
        
        // Create notifications
        for member in members {
            let notificationData: [String: Any] = [
                "user_id": member.userId.uuidString,
                "type": "event_proposal",
                "title": "New event proposal",
                "proposal_id": proposalId
            ]
            
            try await supabase.database
                .from("notifications")
                .insert(values: notificationData)
                .execute()
        }
    }
}

// MARK: - Error Types

enum APIError: Error {
    case authFailed
    case networkError
    case decodingError
    case notFound
}

// MARK: - Response Models

struct GroupMembershipResponse: Codable {
    let groupId: UUID
    let group: Group
}

enum VoteResponse: String, Codable {
    case available
    case maybe
    case unavailable
}
```

```swift
// WebSocketManager.swift
import Foundation
import Supabase
import Combine

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    private var supabase: SupabaseClient
    private var channels: [String: RealtimeChannel] = [:]
    
    @Published var connectionState: ConnectionState = .disconnected
    
    init() {
        self.supabase = APIClient.shared.supabase
        setupConnectionMonitoring()
    }
    
    // MARK: - Connection Management
    
    private func setupConnectionMonitoring() {
        // Monitor network reachability
        // Reconnect on network restore
    }
    
    // MARK: - Subscribe to Proposal Updates
    
    func subscribeToProposal(
        _ proposalId: String,
        onUpdate: @escaping (ProposalUpdate) -> Void
    ) {
        let channelId = "proposal:\(proposalId)"
        
        // Check if already subscribed
        if channels[channelId] != nil {
            return
        }
        
        let channel = supabase.realtime.channel(channelId)
        
        // Listen to vote changes
        channel.on(.postgresChanges(
            event: .insert,
            schema: "public",
            table: "proposal_votes",
            filter: "proposal_id=eq.\(proposalId)"
        )) { payload in
            if let vote = try? JSONDecoder().decode(Vote.self, from: payload.new) {
                onUpdate(.newVote(vote))
            }
        }
        
        // Listen to proposal status changes
        channel.on(.postgresChanges(
            event: .update,
            schema: "public",
            table: "event_proposals",
            filter: "id=eq.\(proposalId)"
        )) { payload in
            if let proposal = try? JSONDecoder().decode(EventProposal.self, from: payload.new) {
                onUpdate(.statusChanged(proposal))
            }
        }
        
        channel.subscribe { status in
            switch status {
            case .subscribed:
                self.connectionState = .connected
            case .closed, .channelError:
                self.connectionState = .disconnected
            default:
                break
            }
        }
        
        channels[channelId] = channel
    }
    
    func unsubscribeFromProposal(_ proposalId: String) {
        let channelId = "proposal:\(proposalId)"
        channels[channelId]?.unsubscribe()
        channels.removeValue(forKey: channelId)
    }
    
    // MARK: - Subscribe to Group Updates
    
    func subscribeToGroup(
        _ groupId: String,
        onUpdate: @escaping (GroupUpdate) -> Void
    ) {
        let channelId = "group:\(groupId)"
        
        if channels[channelId] != nil {
            return
        }
        
        let channel = supabase.realtime.channel(channelId)
        
        // New members
        channel.on(.postgresChanges(
            event: .insert,
            schema: "public",
            table: "group_members",
            filter: "group_id=eq.\(groupId)"
        )) { payload in
            if let member = try? JSONDecoder().decode(GroupMember.self, from: payload.new) {
                onUpdate(.memberAdded(member))
            }
        }
        
        // New proposals
        channel.on(.postgresChanges(
            event: .insert,
            schema: "public",
            table: "event_proposals",
            filter: "group_id=eq.\(groupId)"
        )) { payload in
            if let proposal = try? JSONDecoder().decode(EventProposal.self, from: payload.new) {
                onUpdate(.proposalCreated(proposal))
            }
        }
        
        channel.subscribe()
        channels[channelId] = channel
    }
    
    // MARK: - Cleanup
    
    func disconnectAll() {
        for (_, channel) in channels {
            channel.unsubscribe()
        }
        channels.removeAll()
        connectionState = .disconnected
    }
}

// MARK: - Update Types

enum ProposalUpdate {
    case newVote(Vote)
    case statusChanged(EventProposal)
}

enum GroupUpdate {
    case memberAdded(GroupMember)
    case proposalCreated(EventProposal)
}

enum ConnectionState {
    case connected
    case connecting
    case disconnected
}
```