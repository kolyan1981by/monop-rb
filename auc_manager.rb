require_relative  "game"

module AuctionManager
    def self.init_auction(g)
        cell = g.curr_cell
        auc = Auction.new
        auc.cell = cell
        auc.curr_pl = g.curr
        auc.curr_bid = cell.cost
        auc.last_bidded_player = nil
        auc.auc_pls = g.players.map{|p| p.id}
        g.curr_auction = auc

    end

    def self.run_action_job(g, cmd)

        pl = g.curr_auction.curr_pl
        return if pl.hum? && cmd == "auto" # auto : game update command

        #puts "next_auction_player #{pl.id} players #{g.curr_auction.auc_pls}"

        if !pl.nil? && g.curr_auction.auc_pls.include?(pl.id)
            check_bid(g, pl, cmd)
        end

        check_if_finished(g)
        if g.in_auction? && g.curr_auction.curr_pl.bot?
            sleep(g.update_interval)
            run_action_job(g, cmd)
        end

    end

    def self.check_bid(g, pl, cmd)
        needbid = PlayerManager.go_auc_bid(g,pl,cmd)

        if needbid
            g.curr_auction.next_bid
            g.curr_auction.last_bidded_player = pl.id
            g.log g.get_text("_player_bid") % [pl.name , g.curr_auction.curr_bid]
        else
            g.log g.get_text("_player_left_auction") % pl.name
            g.curr_auction.auc_pls.delete(pl.id)
        end
        next_auction_player(g)

    end

    def self.next_auction_player(g)

        pls = g.curr_auction.auc_pls
        nextp = pls.detect{|p| p > g.curr_auction.curr_pl.id}

        nextp = nextp.nil? ? pls.first : nextp
        g.curr_auction.curr_pl  = g.find_player(nextp)
    end

    def self.check_if_finished(g)
        auc =g.curr_auction
        count = auc.auc_pls.count

        if count ==0 || (count==1 && auc.last_bidded_player == auc.auc_pls.first)
            auc.finished = true
        end

        if auc.finished
            result = count==0? g.get_text("no_winners") : g.get_text("winner") + g.curr_auction.curr_pl.name
            set_auc_winner(g) if count ==1
            g.finish_step("auc_finished , #{result}")
        end

    end

    def self.set_auc_winner(g)
        cell = g.curr_auction.cell
        auc = g.curr_auction
        win_pid = auc.auc_pls.first
        pl= g.find_player(win_pid)
        g.map.set_owner(pl, cell, auc.curr_bid)

    end
end
