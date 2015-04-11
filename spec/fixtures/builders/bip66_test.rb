#!/usr/bin/env ruby
#
# This is a port of sipa's test here but the TODOs are implemented: https://github.com/bitcoin/bitcoin/pull/5713/files
# It is intended to test the soft fork switch-over logic.
# See: https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki#deployment
#
$:.unshift( File.expand_path("../../lib", __FILE__) )
require 'bitcoin'
require_relative '../../support/blockchain'

class BIP66Test

  OLD_VERSION = 2
  NEW_VERSION = 3

  def initialize
    # genesis
    @blockchain = Blockchain.new(60*60*2000)
    @key = @blockchain.new_key('key')
    @time = @blockchain.time
    @height = @blockchain.next_height(:main)
    b = @blockchain.build_next_block(nil, @height, [], @time)
    @blockchain.chain[:main][@height] = b
    @blockchain.add_block_in_sequence(b)
  end

  # helper
  def new_block(prev_block, version, txs=[])
    @height = @blockchain.next_height(:main)
    block = @blockchain.build_next_block(prev_block, @height, txs, @time+=Bitcoin.network[:next_block_time_target], 0, @key, version)
    @blockchain.add_block_in_sequence(block)
    block
  end

  def build_nonder_tx(spend_coinbase_num)
    prev_tx = @blockchain.chain[:main][spend_coinbase_num].tx.first
    value = prev_tx.outputs[0].value
    tx = Bitcoin::Protocol::Tx.new
    tx.add_in(Bitcoin::Protocol::TxIn.new(prev_tx.binary_hash, 0, 0))
    tx.add_out(Bitcoin::Protocol::TxOut.value_to_address(value, @key.addr))
    signature = @key.sign(tx.signature_hash_for_input(0, prev_tx))
    signature += "\x00"*100 # pad the signature with 0s to become uncompliant with DERSIG
    raise "signature is DERSIG compliant" if Bitcoin::Script.is_der_signature?(signature)
    tx.in[0].script_sig = Bitcoin::Script.to_signature_pubkey_script(signature, nil)
    tx = Bitcoin::Protocol::Tx.new(tx.to_payload)
    raise "failed to generate tx" unless tx.verify_input_signature(0, prev_tx) == true
    tx
  end

  def build_test
    b = @blockchain.blocks[0]

    # Mine some old-version blocks
    100.times do
      b = new_block(b, OLD_VERSION)
      @blockchain.chain[:main][@height] = b
    end

    # Mine 749 new-version blocks
    749.times do
      b = new_block(b, NEW_VERSION)
      @blockchain.chain[:main][@height] = b
    end

    # Mine 1 new-version block but includes tx with incompatible signature.
    # Verify DERSIG isn't enforced yet
    tx = build_nonder_tx(1)
    b = new_block(b, NEW_VERSION, [tx])
    @blockchain.chain[:main][@height] = b

    # Mine 1 new-version block but includes tx with incompatible signature.
    # Verify DERSIG is now enforced
    tx = build_nonder_tx(2)
    nope = new_block(b, NEW_VERSION, [tx])
    # Expected that we reject this
    @blockchain.chain[:reject][@height] = nope

    # Mine 199 new-version blocks
    199.times do
      b = new_block(b, NEW_VERSION)
      @blockchain.chain[:main][@height] = b
    end

    # Mine 1 old-version block
    b = new_block(b, OLD_VERSION)
    @blockchain.chain[:main][@height] = b

    # Mine 1 new-version block
    b = new_block(b, NEW_VERSION)
    @blockchain.chain[:main][@height] = b

    # Mine 1 old-version blocks
    nope = new_block(b, OLD_VERSION)
    # Expected that we reject this
    @blockchain.chain[:reject][@height] = nope

    # Mine 1 new-version block
    b = new_block(b, NEW_VERSION)
    @blockchain.chain[:main][@height] = b

    # dump the chain
    @blockchain.pretty_print_json
  end
end

BIP66Test.new.build_test
